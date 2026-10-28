import BackgroundTasks
import SwiftData
import SwiftUI

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let container: ModelContainer
    let clock: AppClock
    let router: Router
    let store: EventStore
    let sync: SyncService
    let reminders: ReminderService
    let favorites: FavoritesStore
    let connectivity: Connectivity

    private init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: ScheduleSnapshot.self, Favorite.self)
        } catch {
            fatalError("No se pudo abrir SwiftData: \(error)")
        }
        let context = container.mainContext
        let (schedule, updated) = SyncService.loadInitial(context: context)
        let store = EventStore(schedule: schedule, lastUpdated: updated)
        let reminders = ReminderService()
        let favorites = FavoritesStore(context: context, reminders: reminders, store: store)
        let sync = SyncService(remoteURL: AppConfig.agendaURL, context: context, store: store)
        sync.onScheduleChanged = { [weak favorites] schedule in
            await favorites?.scheduleDidChange(schedule)
        }

        self.container = container
        self.store = store
        self.reminders = reminders
        self.favorites = favorites
        self.sync = sync
        self.clock = AppClock()
        self.router = Router()
        self.connectivity = Connectivity()
    }

    /// Al abrir, al volver a primer plano y en segundo plano: sincroniza y rellena recordatorios.
    func refreshAll() async {
        await sync.refresh()
        await favorites.reconcileReminders()
    }

    func backgroundRefresh() async {
        BackgroundRefresh.schedule()
        await refreshAll()
    }
}

enum BackgroundRefresh {
    static let identifier = "com.trescloud.evento.refresh"

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
