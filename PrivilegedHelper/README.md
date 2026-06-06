# Privileged Helper (optional)

This folder contains a ready-to-wire **XPC privileged helper** that scans
root-only system files without the per-scan admin password prompt used by the
built-in "Scan as Administrator" feature.

> ⚠️ It is **not** part of the Xcode project on purpose: a privileged helper only
> works when signed with a paid **Apple Developer ID**, and adding an unsigned
> second target would break the main app build. The app ships today with the
> authorized-`du` administrator scan (`PrivilegedScanner.swift`), which needs no
> helper. Add this helper only when you have a Developer ID and want a smoother
> experience.

## Files

- `HelperProtocol.swift` — the shared XPC interface (add to **both** targets).
- `main.swift` — the helper daemon's entry point (helper target only).
- `net.slaats.SpaceMonger.Helper.plist` — the launchd plist for the daemon.
- `AppSideManager.swift.example` — app-side code to register and call the helper,
  with a fallback to the authorized-`du` scan.

## Setup (with a Developer ID)

1. **Add a new target**: *File → New → Target → Command Line Tool*, name it
   `SpaceMongerHelper`, language Swift.
2. Add `main.swift` and `HelperProtocol.swift` to the helper target. Add
   `HelperProtocol.swift` to the **app** target too.
3. In the helper target's **Info.plist**, the executable name must be
   `SpaceMongerHelper` (matches `BundleProgram` in the launchd plist).
4. Put `net.slaats.SpaceMonger.Helper.plist` in the **app** under
   `Contents/Library/LaunchDaemons/` via a *Copy Files* build phase
   (destination: Wrapper, subpath `Contents/Library/LaunchDaemons`).
5. Embed the helper executable in the app under `Contents/MacOS/` via a
   *Copy Files* / dependency so it ships inside the bundle.
6. Sign **both** the app and the helper with the **same Developer ID Team**, and
   enable the **Hardened Runtime**.
7. In `main.swift`, implement the `shouldAcceptNewConnection` code-signing check
   (verify the client's audit token against your Team ID) — see the `TODO`.
8. Copy `AppSideManager.swift.example` into the app target (rename to `.swift`),
   then call `PrivilegedHelperManager.registerIfNeeded()` and route the
   administrator scan through it, parsing the returned `du` file with the same
   logic as `PrivilegedScanner.buildTree`.

## Security notes

- Always verify the connecting client's code signature before serving requests.
- The helper only measures sizes (runs `du`); it performs no deletions.
- Apple's `SMAppService` (macOS 13+) replaces the deprecated `SMJobBless`.
