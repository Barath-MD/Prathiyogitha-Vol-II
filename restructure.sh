#!/usr/bin/env bash
# Restructure repository into assets/ and pages/
# Usage: chmod +x restructure.sh && ./restructure.sh
# IMPORTANT: Run this in a clean working tree (no unstaged changes).
set -euo pipefail

# Directories to create
dirs=(
  "assets/images"
  "assets/videos"
  "assets/audio"
  "assets/fonts"
  "assets/icons"
  "pages"
  "scripts"
)

echo "Creating directories..."
for d in "${dirs[@]}"; do
  mkdir -p "$d"
done

# Helper to run git mv if file is tracked, else normal mv
move_file() {
  local src="$1"
  local dst_dir="$2"
  if git ls-files --error-unmatch -- "$src" > /dev/null 2>&1; then
    git mv -- "$src" "$dst_dir/"
  else
    mv -- "$src" "$dst_dir/"
    git add -- "$dst_dir/$(basename "$src")"
  fi
}

# Move images
echo "Moving image files..."
shopt -s nullglob
for ext in jpg jpeg png gif svg JPG JPEG PNG GIF SVG; do
  for f in *."$ext"; do
    move_file "$f" "assets/images"
  done
done
shopt -u nullglob

# Move large images that may have spaces — handle quoted names
echo "Moving other image-like files (case/space-safe)..."
IFS=$'\n'
for f in $(git ls-files -z | tr '\0' '\n' | grep -Ei '\.(png|jpe?g|gif|svg)$' || true); do
  # already moved above by pattern for files in working dir; this catches tracked files in nested/odd names
  base=$(basename "$f")
  if [ ! -e "assets/images/$base" ]; then
    move_file "$f" "assets/images"
  fi
done
unset IFS

# Move videos
echo "Moving video files..."
for ext in mp4 webm mkv; do
  for f in *."$ext"; do
    move_file "$f" "assets/videos"
  done
done

# Move audio
echo "Moving audio files..."
for ext in mp3 wav ogg; do
  for f in *."$ext"; do
    move_file "$f" "assets/audio"
  done
done

# Move font files if any
echo "Moving fonts..."
for ext in ttf otf woff woff2; do
  for f in *."$ext"; do
    move_file "$f" "assets/fonts"
  done
done

# Move small icons/logo files
echo "Moving standalone icons/logos..."
for f in LOGO*.* newlogo.* logo*.* Unstop.* Brouchure.* BRO*.*; do
  [ -e "$f" ] || continue
  move_file "$f" "assets/icons"
done

# Move site pages (HTML) into pages/, except home.html which will be renamed to index.html
echo "Organizing HTML pages..."
html_pages=(about.html contact.html events.html sponsors.html)
for p in "${html_pages[@]}"; do
  if [ -e "$p" ]; then
    move_file "$p" "pages"
  fi
done

# Rename home.html -> index.html (site entry)
if [ -e "home.html" ]; then
  if git ls-files --error-unmatch -- "home.html" > /dev/null 2>&1; then
    git mv -- "home.html" "index.html"
  else
    mv "home.html" "index.html"
    git add index.html
  fi
  echo "Renamed home.html to index.html"
else
  echo "No home.html found; leaving index.html as-is if present."
fi

# Move leftover single HTML files into pages (except index.html)
for f in *.html; do
  [ "$f" = "index.html" ] && continue
  [ -e "$f" ] || continue
  move_file "$f" "pages"
done

# Add scripts helper into scripts/
cat > scripts/update-refs.sh <<'PATCH'
#!/usr/bin/env bash
# Helper to update references in HTML files to new assets path.
# Usage: ./scripts/update-refs.sh
set -euo pipefail
# Move into repo root
# This script will:
# - for each file in assets/images, replace occurrences of "src=\"<basename>\"" with "src=\"/assets/images/<basename>\""
# - same for videos and audio
for dir in assets/images assets/videos assets/audio assets/icons assets/fonts; do
  [ -d "$dir" ] || continue
  for f in "$dir"/*; do
    base=$(basename "$f")
    # Update tracked HTML files in pages/ and root index.html
    for html in index.html pages/*.html; do
      [ -e "$html" ] || continue
      # Use perl for in-place, case-sensitive replacement, handling spaces
      perl -0777 -pe "s{(src|href)=(['\"])${base}\\2}{\$1=\$2/${dir}/${base}\$2}g" -i "$html" || true
    done
  done
done
echo "Reference update attempt finished. Manually verify pages/*.html and index.html for correctness."
PATCH

chmod +x scripts/update-refs.sh
git add scripts/update-refs.sh || true

echo "Restructure script finished. Please run:"
echo "  git status"
echo "  git commit -m \"chore(restructure): move assets into assets/ and pages/\""
echo "  git push -u origin <branch-name>"
