import Foundation
import Observation
import SwiftData

@MainActor @Observable
final class FavoritesStore {
    private(set) var ids: Set<String> = []
    private(set) var reminderIds: Set<String> = []
    private(set) var titles: [String: String] = [:]

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let reminders: ReminderService
    @ObservationIgnored private let store: EventStore

    init(context: ModelContext, reminders: ReminderService, store: EventStore) {
        self.context = context
        self.reminders = reminders
        self.store = store
        reload()
    }

    func isFavorite(_ id: String) -> Bool { ids.contains(id) }
    func hasReminder(_ id: String) -> Bool { reminderIds.contains(id) }
    func title(for id: String) -> String { titles[id] ?? id }

    func all() -> [Favorite] { (try? context.fetch(FetchDescriptor<Favorite>())) ?? [] }

    private func find(_ id: String) -> Favorite? {
        var d = FetchDescriptor<Favorite>(predicate: #Predicate { $0.sessionId == id })
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }

    private func reload() {
        let favs = all()
        ids = Set(favs.map(\.sessionId))
        reminderIds = Set(favs.filter { $0.reminderEnabled }.map(\.sessionId))
        titles = Dictionary(favs.map { ($0.sessionId, $0.title) }, uniquingKeysWith: { a, _ in a })
    }

    private func save() {
        try? context.save()
        reload()
    }

    func toggle(_ session: Session) async {
        if let existing = find(session.id) {
            context.delete(existing)
            save()
        } else {
            context.insert(Favorite(sessionId: session.id, title: session.title, knownStart: session.start))
            save()
            await reminders.requestPermissionIfNeeded()
        }
        await reconcileReminders()
    }

    func remove(sessionId: String) async {
        guard let fav = find(sessionId) else { return }
        context.delete(fav)
        save()
        await reconcileReminders()
    }

    func setReminder(_ enabled: Bool, for id: String) async {
        guard let fav = find(id) else { return }
        fav.reminderEnabled = enabled
        save()
        if enabled { await reminders.requestPermissionIfNeeded() }
        await reconcileReminders()
    }

    func reconcileReminders() async {
        await reminders.reconcile(favorites: all(), schedule: store.schedule)
    }

    /// Tras cada sincronización: avisa de cambios de horario y cancelaciones, y reprograma.
    func scheduleDidChange(_ schedule: Schedule) async {
        let tz = schedule.event.tz
        let sessions = Dictionary(schedule.sessions.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for fav in all() {
            if let s = sessions[fav.sessionId], !s.isCancelled {
                if abs(s.start.timeIntervalSince(fav.knownStart)) >= 60 {
                    await reminders.notifyNow(
                        title: "Cambio de horario",
                        body: "«\(s.title)» ahora es el \(Fmt.day(s.start, tz)) a las \(Fmt.time(s.start, tz)).",
                        sessionId: s.id)
                    fav.knownStart = s.start
                }
                fav.title = s.title
                fav.cancellationNotified = false
            } else if !fav.cancellationNotified {
                await reminders.notifyNow(title: "Charla cancelada", body: "«\(fav.title)» se ha cancelado.", sessionId: nil)
                fav.cancellationNotified = true
            }
        }
        save()
        await reconcileReminders()
    }
}
