# Prathiyogitha-Vol-II
This repository has been reorganized to separate site pages and static assets.

Top-level layout
- index.html
- pages/               # secondary HTML pages (about, contact, events, sponsors, ...)
- assets/
  - images/
  - videos/
  - audio/
  - fonts/
  - icons/
- scripts/
  - update-refs.sh     # helper to update img/video/audio references inside HTML

What I changed / recommended workflow
1. Keep `index.html` at repository root — this is the default entry point for GitHub Pages.
2. Put other HTML pages into `pages/`.
3. Put all static assets into `assets/...` so paths are consistent.
4. After moving files, references inside HTML will need to be updated to point to `/assets/images/<file>` (or relative paths). Use `scripts/update-refs.sh` as a helper; check its output and manually verify.
5. Commit the changes on a named branch (e.g. `chore/restructure`) and open a PR to review before merging.

Commands to run locally (example)
- Make sure working tree is clean:
  - git status
- Run restructure:
  - chmod +x restructure.sh
  - ./restructure.sh
- Update references (review changes afterwards):
  - ./scripts/update-refs.sh
- Commit:
  - git commit -am "chore(restructure): move assets to assets/, pages/"
  - git push -u origin chore/restructure
- Open a pull request on GitHub to review.

Notes & next steps
- The automatic reference updater is a best-effort helper. Manual verification is required because filenames contain spaces and HTML may reference assets with paths or query strings.
- Optionally: we can convert spaces in filenames to dashes/underscores for cleaner URLs (I can provide a script to do that).
- I only examined a partial listing (API responses limited to 30 items). Please verify that all files were handled as desired.
