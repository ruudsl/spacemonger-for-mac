import XCTest
@testable import SpaceMonger

final class ScanComparisonTests: XCTestCase {
    private func file(_ path: String, _ size: Int64) -> FileNode {
        FileNode(url: URL(fileURLWithPath: path), name: (path as NSString).lastPathComponent,
                 kind: .file, size: size, fileCount: 1)
    }

    func testDiff() {
        let current = FileNode(url: URL(fileURLWithPath: "/x"), name: "x", kind: .directory,
                               children: [file("/x/a", 100), file("/x/b", 50)])
        let other = FileNode(url: URL(fileURLWithPath: "/x"), name: "x", kind: .directory,
                             children: [file("/x/a", 60), file("/x/c", 30)])

        let result = ScanComparison.compare(current: current, currentName: "now",
                                            other: other, otherName: "old")

        XCTAssertEqual(result.grown.first?.path, "/x/a")
        XCTAssertEqual(result.grown.first?.delta, 40)
        XCTAssertEqual(result.added.first?.path, "/x/b")
        XCTAssertEqual(result.removed.first?.path, "/x/c")
        XCTAssertTrue(result.shrunk.isEmpty)
    }
}
