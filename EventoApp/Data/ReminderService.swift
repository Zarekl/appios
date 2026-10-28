import Foundation
import Observation
import UserNotifications

/// Recordatorios locales de favoritos. No necesitan servidor y funcionan sin conexión.
@MainActor @Observable
final class ReminderService {
    static let leadOptions = [5, 10, 15]
    /// iOS permite 64 pendientes por app; dejamos margen para avisos de cambios.
    static let maxPending = 60

    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    var leadMinutes: Int = (UserDefaults.standard.object(forKey: "leadMinutes") as? Int) ?? 10 {
        didSet { UserDefaults.standard.set(leadMinutes, forKey: "leadMinutes") }
    }
    @ObservationIgnored private let center = UNUserNotificationCenter.current()

    var isDenied: Bool { authorization == .denied }
    var canSchedule: Bool {
        authorization == .authorized || authorization == .provisional || authorization == .ephemeral
    }

    func refreshAuthorization() async {
        authorization = await center.notificationSettings().authorizationStatus
    }

    /// Permiso en contexto: se llama la primera vez que el usuario marca un favorito.
    @discardableResult
    func requestPermissionIfNeeded() async -> Bool {
        await refreshAuthorization()
        if authorization == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
        }
        return canSchedule
    }

    /// Recalcula todos los recordatorios: se programan las 60 más próximas.
    func reconcile(favorites: [Favorite], schedule: Schedule, now: Date = Date()) async {
        await refreshAuthorization()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix("session-") }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard canSchedule else { return }

        let lead = TimeInterval(leadMinutes * 60)
        let sessions = Dictionary(schedule.sessions.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let rooms = Dictionary(schedule.rooms.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let due = favorites.filter { $0.reminderEnabled }
            .compactMap { fav -> (Session, Date)? in
                guard let s = sessions[fav.sessionId], !s.isCancelled else { return nil }
                let fire = s.start.addingTimeInterval(-lead)
                return fire > now ? (s, fire) : nil   // si ya pasó la hora del aviso, no se programa
            }
            .sorted { $0.1 < $1.1 }

        for (session, fire) in due.prefix(Self.maxPending) {
            let content = UNMutableNotificationContent()
            content.title = session.title
            let room = rooms[session.roomId]?.name ?? "su sala"
            content.body = "Empieza a las \(Fmt.time(session.start, schedule.event.tz)) en \(room)."
            content.sound = .default
            content.userInfo = ["sessionId": session.id]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(fire.timeIntervalSince(now), 1), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "session-\(session.id)", content: content, trigger: trigger))
        }
    }

    /// Aviso inmediato (cambio de horario o cancelación).
    func notifyNow(title: String, body: String, sessionId: String?) async {
        guard canSchedule else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let sessionId { content.userInfo = ["sessionId": sessionId] }
        try? await center.add(UNNotificationRequest(identifier: "change-\(UUID().uuidString)", content: content, trigger: nil))
    }
}
