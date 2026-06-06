# SpaceMonger for Mac

A **free, native macOS disk-usage analyzer** in the spirit of
[DaisyDisk](https://daisydiskapp.com/). It scans a disk or folder and shows what
is eating your space as an interactive **sunburst map**, lets you drill in and
out, inspect items, and clean up by collecting files and moving them to the
Trash.

Built with **SwiftUI** (macOS 13+).

> This is an independent, open project. It is not affiliated with or endorsed by
> DaisyDisk. It reimplements the *workflow* described in the DaisyDisk user
> guide, not its code or assets.

## Features

Modelled after the DaisyDisk user guide:

| DaisyDisk concept | In SpaceMonger |
| --- | --- |
| Pick a disk to scan | Start screen lists every mounted volume with a used/free bar; or pick any folder |
| Scanning | Fast background scan with live progress (items, bytes, current path) and Cancel |
| Sunburst map | Interactive radial chart; ring size is proportional to on-disk usage |
| Navigation (zoom in/out) | Double-click a sector to zoom in, click the centre to go up, use the breadcrumb to jump |
| Hover & selection | Hover highlights a sector and shows its size in the centre; click selects |
| File info | Detail panel: size, % of folder, % of total, item count, full path |
| Content list | Right-hand list of the current folder, ranked by size, colour-matched to the map |
| The Collector | Drag items (or use the menu) into the Collector, then move them all to the Trash at once |
| Reveal in Finder | From the info panel, context menu, or ⇧⌘R |
| Quick Look | Space-style preview via the info panel, context menu, or ⌘Y |
| Hidden / system space | A grey "System & hidden space" segment accounts for volume space not attributable to readable files |
| Scanning system files | Detects missing **Full Disk Access**, flags unreadable folders with a lock badge, and offers a one-click button to open the right Settings pane |
| Scan as Administrator | A **privileged scan** (authorized `du` as root) measures even root-only system files — prompts once for an admin password |
| Recent scans | The start screen remembers recent disks/folders as **security-scoped bookmarks** so you can re-scan in one click |

### Beyond DaisyDisk — features inspired by [GrandPerspective](https://grandperspectiv.sourceforge.net/)

| GrandPerspective concept | In SpaceMonger |
| --- | --- |
| Treemap view | A squarified **Treemap** layout, switchable with the Sunburst (⌘1 / ⌘2) |
| Colour by file type / depth | Colour modes: **By Folder**, **By File Type**, **By Depth** |
| Filtering | A live **Filter** field over the folder contents |
| Exclude masks | **Exclusions** in Settings (⌘,) — glob patterns like `node_modules`, `*.log` skipped while scanning |
| Reveal / Open / Copy path | All available from the info panel and context menu |
| Delete to Trash | Single items or the whole Collector |
| Save / load scans | Save a scan to a `.smscan` file and re-open it later (⌘S / ⇧⌘O) |
| Compare scans | Diff the current scan against a saved one (grown / shrunk / added / removed) |

Not yet implemented from GrandPerspective (candidates for later): importing
GrandPerspective's own `.gpscan` files and advanced focus masks.

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
  Utilities/
    Formatting.swift          Byte / percent / count formatting
    NodeColor.swift           Shared colour scheme (folder / type / depth)
    FinderActions.swift       Reveal in Finder / move to Trash
    QuickLookController.swift  Quick Look panel
    DiskAccess.swift          Full Disk Access detection & Settings deep-link
    ExcludeMatcher.swift      Glob matching for exclusions
    Localization.swift        loc() / locf() helpers
  Views/… (incl. SettingsView, ComparisonView)
  en.lproj / nl.lproj         Localized UI strings (English + Dutch)
tools/
  make_icon.py                Generates the app icon PNGs (pure stdlib)
```

## How sizing works

Sizes are **on-disk allocated sizes** (`totalFileAllocatedSize`), matching what
Finder reports, base-1000. The scanner does not follow symlinks and never
crosses into other mounted volumes, so figures stay accurate.

## Roadmap / ideas

Done: app icon, recent scans (security-scoped bookmarks), treemap view,
colour-by-type/depth, content filter, Full Disk Access flow, **administrator
scan** of root-only files, **exclude masks**, **save / load / compare scans**,
and English + Dutch localisation (static and dynamic strings).

Still on the list:

- A bundled XPC privileged helper (a more seamless alternative to the
  authorized-`du` administrator scan, but needs Developer ID signing)
- Importing GrandPerspective's own `.gpscan` files
- Advanced focus masks

## License

MIT — see `LICENSE`.
