import EventKit
import Foundation

enum CalendarService {
    struct Denied: LocalizedError {
        var errorDescription: String? { "Permite el acceso al calendario en Ajustes para añadir charlas." }
    }

    @MainActor
    static func add(_ session: Session, room: Room?, tz: TimeZone) async throws {
        let store = EKEventStore()
        guard try await store.requestWriteOnlyAccessToEvents() else { throw Denied() }
        let event = EKEvent(eventStore: store)
        event.title = session.title
        event.startDate = session.start
        event.endDate = session.end
        event.timeZone = tz
        event.location = room?.name
        event.notes = session.abstract
        event.url = URL(string: "evento://charla/\(session.id)")
        event.calendar = store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent)
    }
}
