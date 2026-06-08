import SwiftUI

struct CloudSyncStatusRow: View {
    let status: CloudSyncStatus

    var body: some View {
        HStack {
            Label("iCloud Sync", systemImage: "icloud")
            Spacer()
            Text(detail).foregroundStyle(.secondary).font(.subheadline)
        }
    }

    private var detail: String {
        switch status {
        case .idle, .syncing: return "Syncing…"
        case .upToDate(let date):
            guard let date else { return "Up to date" }
            let f = RelativeDateTimeFormatter(); f.unitsStyle = .short
            return f.localizedString(for: date, relativeTo: Date())
        case .unavailable: return "iCloud unavailable"
        case .error(let msg): return msg
        }
    }
}
