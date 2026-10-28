import Foundation

struct EventInfo: Codable, Hashable, Sendable {
    var name: String
    var venue: String
    var timeZone: String

    var tz: TimeZone { TimeZone(identifier: timeZone) ?? .current }
}

struct Room: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var floor: String
    var capacity: Int
}

struct Track: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var color: String
}

struct SocialLink: Codable, Hashable, Sendable {
    var label: String
    var url: URL
}

struct Speaker: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var role: String
    var company: String
    var bio: String
    var photoURL: URL?
    var links: [SocialLink]

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

struct Session: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var abstract: String
    var start: Date
    var end: Date
    var roomId: String
    var trackId: String
    var speakerIds: [String]
    var format: String
    var level: String
    var language: String
    var updatedAt: Date
    var cancelled: Bool?

    var isCancelled: Bool { cancelled ?? false }
    func isLive(at date: Date) -> Bool { start <= date && date < end }
    func hasEnded(at date: Date) -> Bool { end <= date }
    func progress(at date: Date) -> Double {
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / total, 0), 1)
    }
}

struct ScheduleValidationError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Contenido completo del evento. Se reemplaza en bloque en cada sincronización.
struct Schedule: Codable, Hashable, Sendable {
    var version: String
    var event: EventInfo
    var rooms: [Room]
    var tracks: [Track]
    var speakers: [Speaker]
    var sessions: [Session]

    static func decode(_ data: Data) throws -> Schedule {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let schedule = try decoder.decode(Schedule.self, from: data)
        try schedule.validate()
        return schedule
    }

    func validate() throws {
        guard !sessions.isEmpty else { throw ScheduleValidationError(message: "La agenda no tiene charlas.") }
        guard Set(sessions.map(\.id)).count == sessions.count else {
            throw ScheduleValidationError(message: "Hay charlas con el mismo id.")
        }
        let roomIds = Set(rooms.map(\.id))
        let trackIds = Set(tracks.map(\.id))
        let speakerIds = Set(speakers.map(\.id))
        for s in sessions {
            guard s.end > s.start else { throw ScheduleValidationError(message: "Horario inválido en \(s.id).") }
            guard roomIds.contains(s.roomId), trackIds.contains(s.trackId) else {
                throw ScheduleValidationError(message: "Sala o track desconocido en \(s.id).")
            }
            for sp in s.speakerIds where !speakerIds.contains(sp) {
                throw ScheduleValidationError(message: "Expositor desconocido en \(s.id).")
            }
        }
    }
}
