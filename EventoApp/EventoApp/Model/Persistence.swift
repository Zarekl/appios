import Foundation
import SwiftData

/// Última agenda descargada y validada. Solo existe una.
@Model
final class ScheduleSnapshot {
    @Attribute(.externalStorage) var data: Data
    var etag: String?
    var fetchedAt: Date

    init(data: Data, etag: String?, fetchedAt: Date) {
        self.data = data
        self.etag = etag
        self.fetchedAt = fetchedAt
    }
}

/// Favorito local. Se guarda por sessionId, nunca por posición, y no se toca al sincronizar.
@Model
final class Favorite {
    @Attribute(.unique) var sessionId: String
    var title: String
    var createdAt: Date
    var reminderEnabled: Bool
    /// Último inicio conocido, para detectar cambios de horario.
    var knownStart: Date
    var cancellationNotified: Bool

    init(sessionId: String, title: String, knownStart: Date) {
        self.sessionId = sessionId
        self.title = title
        self.createdAt = .now
        self.reminderEnabled = true
        self.knownStart = knownStart
        self.cancellationNotified = false
    }
}
