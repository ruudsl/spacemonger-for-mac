import Foundation

/// Describes a mounted volume that the user can pick from the start screen,
/// the start screen.
struct VolumeInfo: Identifiable, Hashable {
    let id: URL              // the volume's root URL
    let name: String
    let totalCapacity: Int64
    let availableCapacity: Int64
    let isRemovable: Bool
    let isInternal: Bool
    let formatDescription: String?   // e.g. "APFS", "Mac OS Extended"

    var url: URL { id }
    var usedCapacity: Int64 { max(0, totalCapacity - availableCapacity) }

    var usedFraction: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedCapacity) / Double(totalCapacity)
    }

    /// Enumerates the volumes a user would reasonably want to scan.
    static func mountedVolumes() -> [VolumeInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
            .volumeIsRemovableKey,
            .volumeIsInternalKey,
            .volumeIsBrowsableKey,
            .volumeIsLocalKey,
            .volumeLocalizedFormatDescriptionKey
        ]

        let fm = FileManager.default
        guard let urls = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return [] }

        var result: [VolumeInfo] = []
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            if values.volumeIsBrowsable == false { continue }

            let total = Int64(values.volumeTotalCapacity ?? 0)
            // Prefer the "important usage" figure (matches what Finder reports),
            // fall back to the raw available capacity.
            let available: Int64
            if let important = values.volumeAvailableCapacityForImportantUsage, important > 0 {
                available = important
            } else {
                available = Int64(values.volumeAvailableCapacity ?? 0)
            }

            result.append(VolumeInfo(
                id: url,
                name: values.volumeName ?? url.lastPathComponent,
                totalCapacity: total,
                availableCapacity: available,
                isRemovable: values.volumeIsRemovable ?? false,
                isInternal: values.volumeIsInternal ?? false,
                formatDescription: values.volumeLocalizedFormatDescription
            ))
        }

        // Internal volumes first, then by descending capacity.
        return result.sorted {
            if $0.isInternal != $1.isInternal { return $0.isInternal }
            return $0.totalCapacity > $1.totalCapacity
        }
    }
}
