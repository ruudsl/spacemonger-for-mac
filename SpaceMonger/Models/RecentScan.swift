import Foundation

/// A remembered scan location. The security-scoped bookmark lets us re-open the
/// exact same folder/disk later (and keeps working if the app is sandboxed in a
/// future build).
struct RecentScan: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var path: String
    var bookmark: Data
    var date: Date
    var isVolume: Bool

    init(id: UUID = UUID(), name: String, path: String, bookmark: Data, date: Date = Date(), isVolume: Bool) {
        self.id = id
        self.name = name
        self.path = path
        self.bookmark = bookmark
        self.date = date
        self.isVolume = isVolume
    }
}
