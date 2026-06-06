import XCTest
@testable import SpaceMonger

final class ExcludeMatcherTests: XCTestCase {
    func testGlobMatch() {
        let m = ExcludeMatcher(patterns: ["*.log", "node_modules"])
        XCTAssertTrue(m.matches(name: "debug.log"))
        XCTAssertTrue(m.matches(name: "node_modules"))
        XCTAssertFalse(m.matches(name: "keep.txt"))
    }

    func testCaseInsensitive() {
        let m = ExcludeMatcher(patterns: ["*.LOG"])
        XCTAssertTrue(m.matches(name: "Server.log"))
    }

    func testEmptyNeverMatches() {
        let m = ExcludeMatcher(patterns: [])
        XCTAssertFalse(m.matches(name: "anything"))
    }
}
