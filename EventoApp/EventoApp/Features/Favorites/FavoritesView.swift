import SwiftUI
import UIKit

struct FavoritesView: View {
    @Environment(EventStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites
    @Environment(ReminderService.self) private var reminders
    @Environment(Router.self) private var router
    @Environment(\.openURL) private var openURL

    var body: some View {
        @Bindable var reminders = reminders
        let sessions = store.schedule.sessions.filter { favorites.isFavorite($0.id) }.sorted(by: ScheduleLogic.byStart)
        let overlaps = ScheduleLogic.overlappingIds(sessions)
        let days = ScheduleLogic.days(of: sessions, in: store.tz)
        let missing = favorites.ids.subtracting(store.sessionsById.keys).sorted()

        Group {
            if favorites.ids.isEmpty {
                ContentUnavailableView {
                    Label("Aún no tienes favoritos", systemImage: "star")
                } description: {
                    Text("Toca la estrella de una charla para guardarla aquí. Te avisaremos antes de que empiece.")
                } actions: {
                    Button("Ir a la agenda") { router.tab = .agenda }
                }
            } else {
                List {
                    Section {
                        Picker("Avisarme antes", selection: $reminders.leadMinutes) {
                            ForEach(ReminderService.leadOptions, id: \.self) { m in Text("\(m) min").tag(m) }
                        }
                        if reminders.isDenied {
                            Button {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                            } label: {
                                Label("Las notificaciones están desactivadas. Actívalas en Ajustes.", systemImage: "bell.slash")
                            }
                            .foregroundStyle(.orange)
                        }
                    } footer: {
                        if !overlaps.isEmpty { Text("Algunas favoritas se solapan; están marcadas con «Se solapa».") }
                    }

                    ForEach(days, id: \.self) { day in
                        Section(Fmt.day(day, store.tz)) {
                            ForEach(ScheduleLogic.sessions(sessions, on: day, in: store.tz)) { s in
                                NavigationLink(value: Route.session(s.id)) {
                                    SessionRow(session: s, overlaps: overlaps.contains(s.id))
                                }
                                .swipeActions {
                                    Button("Quitar", role: .destructive) { Task { await favorites.remove(sessionId: s.id) } }
                                    Button {
                                        Task { await favorites.setReminder(!favorites.hasReminder(s.id), for: s.id) }
                                    } label: {
                                        Label(favorites.hasReminder(s.id) ? "Sin aviso" : "Avisar",
                                              systemImage: favorites.hasReminder(s.id) ? "bell.slash" : "bell")
                                    }
                                    .tint(.indigo)
                                }
                            }
                        }
                    }

                    if !missing.isEmpty {
                        Section("Ya no están en la agenda") {
                            ForEach(missing, id: \.self) { id in
                                Text(favorites.title(for: id))
                                    .foregroundStyle(.secondary)
                                    .swipeActions {
                                        Button("Quitar", role: .destructive) { Task { await favorites.remove(sessionId: id) } }
                                    }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favoritos")
        .onChange(of: reminders.leadMinutes) { Task { await favorites.reconcileReminders() } }
        .task { await reminders.refreshAuthorization() }
    }
}
