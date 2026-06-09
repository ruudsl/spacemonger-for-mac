import XCTest
@testable import SpaceMonger

final class SystemPathsTests: XCTestCase {
    func testProtectsSystemLocations() {
        XCTAssertTrue(SystemPaths.isProtected(URL(fileURLWithPath: "/")))
        XCTAssertTrue(SystemPaths.isProtected(URL(fileURLWithPath: "/System")))
        XCTAssertTrue(SystemPaths.isProtected(URL(fileURLWithPath: "/usr/bin")))
        XCTAssertTrue(SystemPaths.isProtected(URL(fileURLWithPath: "/Volumes/Backup")))
    }

    func testAllowsUserContent() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertFalse(SystemPaths.isProtected(home.appendingPathComponent("Documents/report.pdf")))
        XCTAssertFalse(SystemPaths.isProtected(URL(fileURLWithPath: "/usr/local/bin/tool")))
    }

    func testProtectsSystemSubtrees() {
        // Deny-list gaps that used to be deletable.
        XCTAssertTrue(SystemPaths.isProtected(URL(fileURLWithPath: "/Library/LaunchDaemons")))
        XCTAssertTrue(SystemPaths.isProtected(URL(fileURLWithPath: "/private/var/folders/aa/bb")))

        let home = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertTrue(SystemPaths.isProtected(home.appendingPathComponent("Library/Keychains")))
    }

    func testFirmlinkedUserDataIsNotBlanketBlocked() {
        // /System/Volumes/Data/<home>/Documents is the user's own file and must
        // stay deletable, even though it sits under the /System/ tree.
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let dataForm = URL(fileURLWithPath: "/System/Volumes/Data" + home + "/Documents/report.pdf")
        XCTAssertFalse(SystemPaths.isProtected(dataForm))

        // …but the data-volume root itself stays protected.
        XCTAssertTrue(SystemPaths.isProtected(URL(fileURLWithPath: "/System/Volumes/Data")))
    }
}
