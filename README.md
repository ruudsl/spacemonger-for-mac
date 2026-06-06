# SpaceMonger for Mac

**Find it. Free it.** See exactly what's filling your disk and reclaim the space
in the most efficient and easy way.

A **free, native macOS disk-usage analyzer**. It scans a disk or folder and shows
what is eating your space as an interactive **sunburst** or **treemap**, lets you
drill in and out, inspect items, and clean up by collecting files and moving them
to the Trash.

Built with **SwiftUI** (macOS 13+).

## Features

| Area | In SpaceMonger |
| --- | --- |
| Pick a disk to scan | Start screen lists every mounted volume with a used/free bar and file system; or pick any folder |
| Scanning | Concurrent, multi-core background scan with live progress (items, bytes, current path) and Cancel |
| Sunburst map | Interactive radial chart; ring size is proportional to on-disk usage |
| Treemap | A squarified treemap as an alternative layout, switchable from the toolbar |
| Navigation (zoom in/out) | Double-click to zoom in, click the centre to go up, use the breadcrumb to jump |
| Hover & selection | Hover highlights an item and shows its size in the centre; click selects |
| File info | Detail panel: size, % of folder, % of total, item count, full path |
| Content list | Ranked, colour-matched list of the current folder, with a live filter |
| Colour modes | By Folder, By File Type, By Depth |
| Focus masks | Highlight only files matching name / type / minimum-size; everything else is dimmed and filtered |
| The Collector | Drag items (or use the menu) into the Collector, then move them all to the Trash at once |
| Reveal / Open / Copy path | From the info panel, context menu, or menu bar |
| Quick Look | Preview any file with ⌘Y |
| Hidden / system space | A grey "System & hidden space" segment accounts for volume space not attributable to readable files |
| Scanning system files | Detects missing **Full Disk Access**, flags unreadable folders with a lock badge, and offers a one-click button to open the right Settings pane |
| Scan as Administrator | A **privileged scan** (authorized `du` as root) measures even root-only system files — prompts once for an admin password |
| Recent scans | The start screen remembers recent disks/folders as **security-scoped bookmarks** so you can re-scan in one click |
| Save / load / compare | Save a scan to a `.smscan` file, re-open it (also imports `.gpscan`), and diff two scans (grown / shrunk / added / removed) |
| Exclusions | Glob patterns (e.g. `node_modules`, `*.log`) skipped while scanning, set in Settings (⌘,) |
| Safety | Safety stoppers block deletion of system-critical components and whole volumes |
| Snapshots & purgeable | Review and delete local Time Machine snapshots and reclaim purgeable space (Tools menu, or the hidden-space panel) |
| Quick Look | Preview any file with the **Spacebar** or ⌘Y |
| Open With | Open a file in any compatible app from the context menu |
| Privacy | Reads only file metadata (names & sizes); no content, no network, no analytics |
| In-app guide | A built-in user guide under **Help → SpaceMonger Help** (⌘?) |
| Full Disk Access | Status and a one-click link to the right pane, in **Settings** (⌘,) |

### Keyboard shortcuts

- **⌘O** – Scan a folder…
- **⌘R** – Rescan · **⌥⌘R** – Rescan as administrator
- **⌘S** – Save scan · **⇧⌘O** – Open scan
- **⌘,** – Settings (exclusions)
- **⌘Y** – Quick Look the selection
- **⇧⌘O** – Open the selection
- **⇧⌘R** – Reveal the selection in Finder
- **⇧⌘C** – Copy the selection's path
- **⌘D** – Add the selection to the Collector
- **⌘⌫** – Move the selection to the Trash

## Building

Requirements: **Xcode 16 or newer** (the project uses Xcode's synchronized
file groups) on **macOS 13 Ventura or newer**.

```sh
git clone https://github.com/ruudsl/spacemonger-for-mac.git
cd spacemonger-for-mac
open SpaceMonger.xcodeproj
```

Then press **Run** (⌘R). The first time, set your own *Signing Team* under
**Signing & Capabilities** (or leave it on "Sign to Run Locally").

You can also build from the command line:

```sh
xcodebuild -project SpaceMonger.xcodeproj -scheme SpaceMonger -configuration Release build
```

## Permissions

The app is **not sandboxed**, so it scans whatever your account can read.

- **Scanning a folder you pick** works out of the box.
- **Scanning a whole startup disk** needs **Full Disk Access**: open
  *System Settings → Privacy & Security → Full Disk Access* and add SpaceMonger
  (or Xcode while developing). Without it, protected system locations are not
  readable and will show up inside the "System & hidden space" segment.
  SpaceMonger's own **Settings (⌘,)** shows the current status and has a button
  that jumps straight to that pane.

Alternatively, use **Rescan as Administrator** (⌥⌘R, or the banner button after
a scan): this runs the measurement as root via an authorized `du`, so even
root-only system files are counted. You're prompted once for an admin password.

Deletions move items to the **Trash** (never an immediate hard delete), so they
remain recoverable.

## Project layout

```
SpaceMonger/
  SpaceMongerApp.swift        App entry point & menu commands
  Models/
    FileNode.swift            The scanned file tree (sizes, children, parent)
    VolumeInfo.swift          Mounted-volume discovery for the start screen
    DiskScanner.swift         Recursive, cancellable on-disk size measurement
    PrivilegedScanner.swift   Administrator scan via authorized `du`
    RecentScan.swift          A remembered location (security-scoped bookmark)
    ScanArchive.swift         Save / load a scan to a .smscan file
    ScanComparison.swift      Diff two scans
    GPScanImporter.swift      Import a .gpscan file (incl. gzip)
    FocusCriteria.swift       Focus-mask matching rules
    SnapshotManager.swift     List/delete local snapshots, reclaim purgeable space
  ViewModels/
    ScanViewModel.swift       App state: scan lifecycle, navigation, collector
    RecentScansStore.swift    Persists & resolves recent scans
    ExcludeStore.swift        Persisted exclude patterns
  Sunburst/
    SunburstLayout.swift      Pure geometry: segments + hit-testing
    SunburstView.swift        Canvas rendering & pointer interaction
  Treemap/
    TreemapLayout.swift       Squarified treemap geometry + hit-testing
    TreemapView.swift         Canvas rendering & pointer interaction
  Views/
    ContentView.swift         Top-level layout (start / scanning / results)
    DiskSelectionView.swift   Start screen
    ScanProgressView.swift    Progress UI
    BreadcrumbView.swift      Path navigation
    FileInfoView.swift        Selected-item details & actions
    FileListView.swift        Ranked contents list (drag to Collector)
    CollectorView.swift       Drop target + "move to Trash"
    SettingsView.swift        Exclusions preferences
    ComparisonView.swift      Scan diff sheet
    FocusPanelView.swift      Focus-mask popover
    TechSpecsView.swift       Tech Specs sheet
    SnapshotsView.swift       Snapshots & purgeable-space sheet
    HelpView.swift            In-app user guide
  Utilities/
    Formatting.swift          Byte / percent / count formatting
    NodeColor.swift           Shared colour scheme (folder / type / depth)
    FinderActions.swift       Reveal in Finder / move to Trash
    QuickLookController.swift  Quick Look panel
    DiskAccess.swift          Full Disk Access detection & Settings deep-link
    ExcludeMatcher.swift      Glob matching for exclusions
    SystemPaths.swift         Safety stoppers for system-critical paths
    SpacebarQuickLook.swift   Finder-style spacebar Quick Look
    Localization.swift        loc() / locf() helpers
  *.lproj                     Localized UI strings (15 languages)
PrivilegedHelper/             Optional XPC helper (out-of-target; see its README)
tools/
  make_icon.py                Generates the app icon PNGs (pure stdlib)
  make_locales.py             Generates every Localizable.strings (source of truth)
```

## How sizing works

Sizes are **on-disk allocated sizes** (`totalFileAllocatedSize`), matching what
Finder reports, base-1000. The scanner does not follow symlinks and never
crosses into other mounted volumes, so figures stay accurate.

## Recent improvements

Determinate progress, auto-cached last scan, drag-and-drop a folder to scan,
size-unit & default-view/colour preferences, colour-blind palette, follow-symlink
option, confirm-before-delete, exclusions import/export, comparison CSV export,
"Check for Updates", a sample of unreadable folders in the access banner, treemap
cushion shading, hovered full path in the breadcrumb, Cmd/Shift multi-selection
with bulk actions, correct pluralisation (stringsdict), unit tests, and a
CI/notarise pipeline template.

## Roadmap / ideas

Done: app icon, recent scans (security-scoped bookmarks), treemap view,
colour-by-type/depth, content filter, focus masks, Full Disk Access flow,
**administrator scan** of root-only files, exclude masks,
**save / load / compare** scans, `.gpscan` import (incl. gzip-compressed),
concurrent scanning, safety stoppers, **local snapshot & purgeable-space
management** (`tmutil`), **spacebar Quick Look**, **Open With** menu, a
localised Tech Specs sheet, and a 15-language UI.

Also addressed (in safe, build-preserving forms):

- **Live scan feedback** — top-level folder progress (`3 of 12 folders`).
- **Faster scanning** — the scanner prefetches only the resource keys it uses.
- **Keyboard navigation in the map** — arrows move the selection, Return zooms
  in, ⌘↑ goes up a level (ignored while typing).
- **Snapshots & purgeable** — "Free Up Space" reclaims as much as macOS allows
  (per-snapshot sizes aren't exposed by the OS).
- **XPC privileged helper** — the app side is integrated
  (`PrivilegedHelperManager`, Settings → install); it activates once you add and
  sign the helper target from [`PrivilegedHelper/`](PrivilegedHelper/README.md).
- **Sandboxed build variant** — opt-in entitlements + guide in
  [`Distribution/`](Distribution/Sandboxing.md).
- **String Catalog** — a converter (`tools/make_xcstrings.py`) is provided.

The whole UI — including the **Help guide and Tech Specs — is now localised in
all 15 languages** (generated by `tools/make_locales.py`).

Genuinely remaining:

- Deep memory work for multi-million-file disks, and a true streaming tree.
- **Native-speaker review** of the translations (they are currently
  machine-quality; the strings are isolated in the `.lproj` files / the generator
  so reviewers can edit them without touching code).

## Tech Specs

- **Supported disks/sources:** any volume macOS mounts as a file system —
  internal, external, removable, optical, network (NAS/SMB/AFP/NFS/WebDAV via the
  Finder), disk images and FUSE volumes. File systems: APFS, HFS+/HFS, exFAT,
  FAT, NTFS and others.
- **Scanning:** concurrent, multi-core measurement via macOS file-system APIs;
  speed depends on disk type, file system and file count.
- **Hidden space:** the difference between used space and scannable files —
  shrink it with Full Disk Access or Scan as Administrator.
- **File preview:** built-in Quick Look (⌘Y).
- **Safety:** stoppers prevent deleting system-critical components; no automatic
  cleaning; deletions go to the Trash.
- **Privacy:** reads only metadata (names & sizes); nothing leaves your Mac.
- **Requirements:** macOS 13+ (Apple Silicon & Intel, 64-bit).
- **Languages:** English, Français, Deutsch, Italiano, Polski, Русский, Español,
  Português, Svenska, Türkçe, Українська, 简体中文, 繁體中文, 日本語, Nederlands.

The same information is available in-app via **Help → SpaceMonger Tech Specs**.

## License

MIT — see `LICENSE`.
