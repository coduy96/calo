import Foundation

/// Disk-backed image store for `WeightEntry` progress photos.
///
/// Same rationale as `FoodImageStore`: persisting binary image data inside
/// the `weightEntries` UserDefaults JSON would silently break past the 4 MiB
/// cap iOS enforces on UserDefaults writes. Photos live as individual JPEGs
/// under `Application Support/voidpen-weight-photos/<uuid>.jpg`, and the
/// `WeightEntry` only persists the filename. The encoded entry JSON stays
/// tiny so UserDefaults stays well under its cap.
struct WeightPhotoStore {
    static let shared = WeightPhotoStore()

    private let folderName = "voidpen-weight-photos"

    private var folderURL: URL? {
        guard let base = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        let url = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// Writes `data` to disk under a stable filename derived from `id`.
    /// Returns the filename (not full path) on success.
    @discardableResult
    func store(data: Data, for id: UUID) -> String? {
        guard let folderURL else { return nil }
        let filename = "\(id.uuidString).jpg"
        let url = folderURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    /// Reads the bytes at `filename` (not a full path), or nil if missing.
    func load(filename: String) -> Data? {
        guard let folderURL else { return nil }
        let url = folderURL.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    /// Best-effort delete. Silent no-op if the file is already gone.
    func delete(filename: String) {
        guard let folderURL else { return }
        let url = folderURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    /// Full file URL for a stored filename, or nil if the container is unavailable.
    /// The file may not exist yet — callers should check before reading.
    func fileURL(for filename: String) -> URL? {
        guard let folderURL else { return nil }
        return folderURL.appendingPathComponent(filename)
    }

    /// Wipes the entire photo folder (used by Delete All Data).
    func deleteAll() {
        guard let folderURL else { return }
        try? FileManager.default.removeItem(at: folderURL)
    }
}
