import XCTest
@testable import SpaceMonger

final class FileNodeTests: XCTestCase {
    func testRemoveChildAdjustsSize() {
        let a = FileNode(url: URL(fileURLWithPath: "/x/a"), name: "a", kind: .file, size: 100, fileCount: 1)
        let b = FileNode(url: URL(fileURLWithPath: "/x/b"), name: "b", kind: .file, size: 25, fileCount: 1)
        let dir = FileNode(url: URL(fileURLWithPath: "/x"), name: "x", kind: .directory,
                           size: 125, fileCount: 2, children: [a, b])

        dir.removeChild(a)

        XCTAssertEqual(dir.size, 25)
        XCTAssertEqual(dir.fileCount, 1)
        XCTAssertEqual(dir.children.count, 1)
    }

    func testFractionOfAncestor() {
        let a = FileNode(url: URL(fileURLWithPath: "/x/a"), name: "a", kind: .file, size: 25, fileCount: 1)
        let dir = FileNode(url: URL(fileURLWithPath: "/x"), name: "x", kind: .directory,
                           size: 100, fileCount: 1, children: [a])
        XCTAssertEqual(a.fraction(of: dir), 0.25, accuracy: 0.0001)
    }
}
