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
}
