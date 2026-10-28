import Foundation
import Observation

/// Almacén de lectura del contenido del evento, indexado para las vistas.
@MainActor @Observable
final class EventStore {
    private(set) var schedule: Schedule
    private(set) var lastUpdated: Date?
    private(set) var sessionsById: [String: Session] = [:]
    private(set) var speakersById: [String: Speaker] = [:]
    private(set) var roomsById: [String: Room] = [:]
    private(set) var tracksById: [String: Track] = [:]
    private(set) var sessionsBySpeaker: [String: [Session]] = [:]

    init(schedule: Schedule, lastUpdated: Date?) {
        self.schedule = schedule
        self.lastUpdated = lastUpdated
        reindex()
    }

    func apply(_ schedule: Schedule, updatedAt: Date?) {
        self.schedule = schedule
        self.lastUpdated = updatedAt
        reindex()
    }

    func markChecked(_ date: Date) { lastUpdated = date }

    private func reindex() {
        sessionsById = Dictionary(schedule.sessions.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        speakersById = Dictionary(schedule.speakers.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        roomsById = Dictionary(schedule.rooms.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        tracksById = Dictionary(schedule.tracks.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var bySpeaker: [String: [Session]] = [:]
        for s in schedule.sessions.sorted(by: ScheduleLogic.byStart) {
            for sp in s.speakerIds { bySpeaker[sp, default: []].append(s) }
        }
        sessionsBySpeaker = bySpeaker
    }

    var tz: TimeZone { schedule.event.tz }
    var days: [Date] { ScheduleLogic.days(of: schedule.sessions, in: tz) }
    var formats: [String] { Array(Set(schedule.sessions.map(\.format))).sorted() }
    var levels: [String] { Array(Set(schedule.sessions.map(\.level))).sorted() }
    var languages: [String] { Array(Set(schedule.sessions.map(\.language))).sorted() }

    func room(_ s: Session) -> Room? { roomsById[s.roomId] }
    func track(_ s: Session) -> Track? { tracksById[s.trackId] }
    func speakers(_ s: Session) -> [Speaker] { s.speakerIds.compactMap { speakersById[$0] } }
}
