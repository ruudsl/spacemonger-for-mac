# Sandboxed (App Store) build variant

SpaceMonger ships **non-sandboxed** by default so it can scan whole disks (with
Full Disk Access) and run the authorized administrator scan. For a Mac App Store
build you need the **App Sandbox**, which trades that breadth for a folder-picker
model.

## What still works sandboxed

- Scanning any folder/disk the user picks in the open panel.
- Re-opening recent scans (we already store **security-scoped bookmarks**).
- The sunburst/treemap, Collector, Quick Look, Reveal, Copy Path, save/compare.

## What does **not** work sandboxed

- Scanning an entire startup disk silently (Full Disk Access is unavailable to
  sandboxed apps).
- **Scan as Administrator** / the privileged helper.
- Deleting outside the sandbox without a user grant.

## How to enable

1. Select the app target → **Signing & Capabilities → + Capability → App Sandbox**.
2. Set **CODE_SIGN_ENTITLEMENTS** to `Distribution/Sandbox.entitlements`
   (or merge its keys into the generated entitlements).
3. Wrap each scanned URL in `startAccessingSecurityScopedResource()` /
   `stopAccessingSecurityScopedResource()` — `RecentScansStore` already does this
   for resolved bookmarks; the open-panel URL is granted for the session.
4. Remove or guard the administrator-scan UI in a sandboxed build.

Keep two configurations (Direct / App Store) or an `.xcconfig` switch so you can
ship both.
