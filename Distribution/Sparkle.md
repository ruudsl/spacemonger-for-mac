# Real auto-updates with Sparkle

SpaceMonger's update code is already wired for [Sparkle](https://sparkle-project.org)
behind `#if canImport(Sparkle)` (see `SpaceMonger/Utilities/SparkleUpdater.swift`).
Until you add the Sparkle package it builds fine and uses the GitHub-Releases
check; once you complete the steps below, the in-app "Check for updates" and the
automatic checks download, install and relaunch the new version.

> Requires a paid **Apple Developer ID** (Sparkle verifies the app's code
> signature) and an **EdDSA** signing key for the updates.

## 1. Add the Sparkle package

Xcode ▸ **File ▸ Add Package Dependencies…** ▸
`https://github.com/sparkle-project/Sparkle` ▸ add the **Sparkle** library to the
**SpaceMonger** target. (`SparkleUpdater.swift` lights up automatically.)

## 2. Generate signing keys

From the Sparkle package's artifacts (or download Sparkle's tools):

```sh
./bin/generate_keys
```

This stores a private key in your login keychain and prints a **public** key.
Copy the public key — it goes in the Info.plist as `SUPublicEDKey`.

## 3. Info.plist keys

Add these to the target (Target ▸ **Info** tab, or as `INFOPLIST_KEY_…` build
settings since the project uses a generated Info.plist):

| Key | Value |
| --- | --- |
| `SUFeedURL` | `https://raw.githubusercontent.com/ruudsl/spacemonger-for-mac/main/appcast.xml` |
| `SUPublicEDKey` | the public key from step 2 |
| `SUEnableInstallerLauncherService` | `YES` (only if you ship a sandboxed build) |

Hardened Runtime stays **on**.

## 4. Build, sign, package

1. **Product ▸ Archive**, export a **Developer ID**-signed app (or use
   `.github/workflows/release.yml`).
2. Zip it: `ditto -c -k --keepParent SpaceMonger.app SpaceMonger-1.1.zip`.
3. Sign the archive:

```sh
./bin/sign_update SpaceMonger-1.1.zip
# -> sparkle:edSignature="…" length="…"
```

## 5. Update the appcast and release

1. Upload `SpaceMonger-1.1.zip` as an asset on a GitHub Release (tag `v1.1`).
2. Add an `<item>` to [`appcast.xml`](../appcast.xml) with the new version, the
   asset URL, and the signature/length from step 4, then commit it.

Sparkle reads `appcast.xml` at `SUFeedURL`, compares versions, and offers the
update. You can automate steps 4–5 in CI with Sparkle's `generate_appcast`
(store the private key as a secret).

## How the app behaves

- **With Sparkle present:** "Check for Updates…" and the automatic checks use
  Sparkle's full updater (download + install + relaunch).
- **Without Sparkle:** the app falls back to checking GitHub Releases and shows a
  Download button that opens the release page.
