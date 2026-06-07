# Screenshots

Put PNGs here and reference them from the main `README.md`.

Suggested set:

- `start.png` — the disk selection / start screen
- `sunburst.png` — the sunburst map of a scan
- `treemap.png` — the treemap layout
- `collector.png` — the Collector with items queued for the Trash
- `settings.png` — the Settings window

How to capture on macOS: **⇧⌘4** then drag (or press Space to capture a window);
or **⇧⌘5** for more options. Drag the resulting file into this folder.

## Privacy note (is this a GDPR/AVG thing?)

Screenshots of a disk analyzer reveal real **file/folder names and full paths**,
which can be personal data (your name in a path, client/project names, etc.).

- Publishing **your own** data is your choice — it isn't a GDPR violation per se,
  but think twice before putting private paths in a public repo (they're then
  indexed and cached).
- It **does** become a privacy concern if a screenshot shows **other people's**
  personal data (names, e-mails, client files).

Safer options:

- **Generate a privacy-free demo folder** and scan that:

  ```sh
  tools/make_demo_tree.sh                 # ~/Desktop/SpaceMonger Demo (~450 MB)
  SCALE=2 tools/make_demo_tree.sh ~/Desktop/"Demo"   # bigger
  ```

  It contains only dummy files (Photos, Videos, Music, a web project with
  `node_modules`, an app bundle, …) with varied sizes/types so the map looks
  good. Drag it to the Trash when you're done.
- Or scan a fresh **test user account** or a small **external/USB disk**.
- **Redact or blur** sensitive names before committing (the app's colour-blocks
  read fine even with names blurred).
