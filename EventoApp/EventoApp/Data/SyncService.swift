import Foundation
import Observation
import SwiftData

enum AppConfig {
    /// URL del JSON publicado (backend propio, Odoo Eventos…). nil = solo la agenda empaquetada.
    static let agendaURL: URL? = nil
}

/// Descarga la agenda en segundo plano y la guarda de forma atómica. Nunca bloquea la interfaz.
@MainActor @Observable
final class SyncService {
    enum Status: Equatable { case idle, syncing, offline, failed(String), notConfigured }

    private(set) var status: Status = .idle
    @ObservationIgnored private let remoteURL: URL?
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let store: EventStore
    @ObservationIgnored var onScheduleChanged: (@MainActor (Schedule) async -> Void)?

    init(remoteURL: URL?, context: ModelContext, store: EventStore) {
        self.remoteURL = remoteURL
        self.context = context
        self.store = store
        if remoteURL == nil { status = .notConfigured }
    }

    // MARK: Carga inicial

    static func loadInitial(context: ModelContext) -> (Schedule, Date?) {
        if let snap = latestSnapshot(context), let schedule = try? Schedule.decode(snap.data) {
            return (schedule, snap.fetchedAt)
        }
        return (bundled(), nil)
    }

    static func bundled() -> Schedule {
        guard let url = Bundle.main.url(forResource: "agenda", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let schedule = try? Schedule.decode(data) else {
            fatalError("Falta agenda.json en el bundle o no es válido.")
        }
        return schedule
    }

    private static func latestSnapshot(_ context: ModelContext) -> ScheduleSnapshot? {
        var d = FetchDescriptor<ScheduleSnapshot>(sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)])
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }

    // MARK: Actualización

    func refresh() async {
        guard let remoteURL else { status = .notConfigured; return }
        guard status != .syncing else { return }
        status = .syncing

        var request = URLRequest(url: remoteURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let snapshot = Self.latestSnapshot(context)
        if let etag = snapshot?.etag { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 304 {
                snapshot?.fetchedAt = .now
                try? context.save()
                store.markChecked(.now)
                status = .idle
                return
            }
            guard (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }

            // Se valida antes de tocar nada: si falla, se conserva la agenda anterior.
            let schedule = try Schedule.decode(data)
            let etag = http.value(forHTTPHeaderField: "ETag")
            try context.transaction {
                try context.delete(model: ScheduleSnapshot.self)
                context.insert(ScheduleSnapshot(data: data, etag: etag, fetchedAt: .now))
            }
            store.apply(schedule, updatedAt: .now)
            status = .idle
            await onScheduleChanged?(schedule)
        } catch let error as URLError where Self.offlineCodes.contains(error.code) {
            status = .offline
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private static let offlineCodes: [URLError.Code] = [
        .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost,
    ]
}
