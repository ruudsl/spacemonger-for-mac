import XCTest
@testable import SpaceMonger

final class DiskScannerTests: XCTestCase {

    /// Two directory entries pointing at the same inode (a hard link) must
    /// contribute their on-disk size only once, not twice.
    func testHardLinkedFilesCountedOnce() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("sm-hardlink-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: dir) }

        let original = dir.appendingPathComponent("original.bin")
        try Data(repeating: 0xAB, count: 64 * 1024).write(to: original)   // 64 KB
        let link = dir.appendingPathComponent("hardlink.bin")
        try fm.linkItem(at: original, to: link)   // hard link → same inode

        let result = try DiskScanner().scan(at: dir, isCancelled: { false }, progress: { _ in })

        // Both entries are listed…
        XCTAssertEqual(result.root.fileCount, 2)

        // …but the shared inode's bytes are counted a single time.
        let single = DiskScanner.allocatedSize(try original.resourceValues(forKeys: [
            .totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey
        ]))
        XCTAssertGreaterThan(single, 0)
        XCTAssertEqual(result.root.size, single)
    }

    /// A plain file with no extra links is unaffected by the dedup path.
    func testSingleFileCountedNormally() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("sm-single-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: dir) }

        let file = dir.appendingPathComponent("file.bin")
        try Data(repeating: 0x01, count: 32 * 1024).write(to: file)

        let result = try DiskScanner().scan(at: dir, isCancelled: { false }, progress: { _ in })

        let single = DiskScanner.allocatedSize(try file.resourceValues(forKeys: [
            .totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey
        ]))
        XCTAssertEqual(result.root.fileCount, 1)
        XCTAssertEqual(result.root.size, single)
    }
}
