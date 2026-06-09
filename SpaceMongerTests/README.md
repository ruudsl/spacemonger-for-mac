# SpaceMongerTests

Unit tests for the pure logic (no AppKit/UI). They live outside the app's
synchronized source folder so they don't affect the app build until you add a
test target.

## Add the test target (one-time, in Xcode)

1. **File → New → Target… → Unit Testing Bundle**, name it `SpaceMongerTests`,
   set *Target to be Tested* = `SpaceMonger`.
2. Delete the auto-created sample file, then drag the `.swift` files in this
   folder into the new target (check "SpaceMongerTests" membership).
3. The tests use `@testable import SpaceMonger`, so build the app target at
   least once first.
4. Run with **⌘U**.

These cover `ExcludeMatcher`, `SystemPaths`, `ScanComparison`, `FileNode` and
`DiskScanner` (hard-link de-duplication).
UI tests (snapshot/integration) can be added the same way via a *UI Testing
Bundle*.
