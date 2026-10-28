import Foundation

enum EventPhase: Equatable {
    case before(Date)
    case during
    case after
}

/// Lógica de horarios pura (sin estado), para poder probarla con un reloj inyectado.
enum ScheduleLogic {
    static func eventCalendar(_ tz: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        cal.locale = Fmt.locale
        return cal
    }

    static func phase(of sessions: [Session], at now: Date) -> EventPhase {
        let active = sessions.filter { !$0.isCancelled }
        guard let first = active.map(\.start).min(), let last = active.map(\.end).max() else { return .after }
        if now < first { return .before(first) }
        if now >= last { return .after }
        return .during
    }

    static func live(_ sessions: [Session], at now: Date) -> [Session] {
        sessions.filter { !$0.isCancelled && $0.isLive(at: now) }.sorted(by: byStart)
    }

    static func upcoming(_ sessions: [Session], at now: Date, within window: TimeInterval = 3600) -> [Session] {
        let limit = now.addingTimeInterval(window)
        return sessions.filter { !$0.isCancelled && $0.start > now && $0.start <= limit }.sorted(by: byStart)
    }

    static func next(_ sessions: [Session], after now: Date) -> Session? {
        sessions.filter { !$0.isCancelled && $0.start > now }.min(by: byStart)
    }

    /// Ids de las charlas que se solapan con alguna otra del conjunto.
    static func overlappingIds(_ sessions: [Session]) -> Set<String> {
        let sorted = sessions.filter { !$0.isCancelled }.sorted(by: byStart)
        var result = Set<String>()
        for i in sorted.indices {
            for j in sorted.indices where j > i {
                if sorted[j].start >= sorted[i].end { break }
                result.insert(sorted[i].id)
                result.insert(sorted[j].id)
            }
        }
        return result
    }

    static func days(of sessions: [Session], in tz: TimeZone) -> [Date] {
        let cal = eventCalendar(tz)
        return Array(Set(sessions.map { cal.startOfDay(for: $0.start) })).sorted()
    }

    static func sessions(_ sessions: [Session], on day: Date, in tz: TimeZone) -> [Session] {
        let cal = eventCalendar(tz)
        return sessions.filter { cal.isDate($0.start, inSameDayAs: day) }.sorted(by: byStart)
    }

    static func byStart(_ a: Session, _ b: Session) -> Bool {
        a.start == b.start ? a.title < b.title : a.start < b.start
    }
}
