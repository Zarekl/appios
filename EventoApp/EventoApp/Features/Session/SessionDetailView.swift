import SwiftUI
import UIKit

struct SessionDetailView: View {
    let sessionId: String
    @Environment(EventStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites
    @Environment(ReminderService.self) private var reminders
    @Environment(AppClock.self) private var clock
    @Environment(\.openURL) private var openURL
    @State private var calendarMessage: String?

    var body: some View {
        if let session = store.sessionsById[sessionId] {
            content(session)
        } else {
            ContentUnavailableView("Charla no encontrada", systemImage: "calendar.badge.exclamationmark",
                                   description: Text("Puede que se haya retirado de la agenda."))
        }
    }

    private func content(_ s: Session) -> some View {
        let tz = store.tz
        let room = store.room(s)
        let track = store.track(s)
        let speakers = store.speakers(s)
        let isFavorite = favorites.isFavorite(s.id)

        return List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    TimelineView(.everyMinute) { ctx in StatusBadge(session: s, now: clock.now(ctx.date)) }
                    Text(s.title).font(.title2.bold())
                    if let track { Tag(text: track.name, color: Color(hex: track.color)) }
                }
                .padding(.vertical, 4)
                LabeledContent("Día", value: Fmt.day(s.start, tz))
                LabeledContent("Horario", value: Fmt.range(s, tz))
                LabeledContent("Sala", value: [room?.name, room?.floor].compactMap { $0 }.joined(separator: ", "))
                LabeledContent("Formato", value: s.format)
                LabeledContent("Nivel", value: s.level)
                LabeledContent("Idioma", value: s.language)
            }

            if !s.abstract.isEmpty {
                Section("Descripción") { Text(s.abstract) }
            }

            if !speakers.isEmpty {
                Section(speakers.count == 1 ? "Expositor" : "Expositores") {
                    ForEach(speakers) { sp in
                        NavigationLink(value: Route.speaker(sp.id)) { SpeakerRow(speaker: sp) }
                    }
                }
            }

            Section {
                Button { Task { await favorites.toggle(s) } } label: {
                    Label(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos",
                          systemImage: isFavorite ? "star.slash" : "star")
                }
                if isFavorite {
                    Toggle(isOn: Binding(
                        get: { favorites.hasReminder(s.id) },
                        set: { value in Task { await favorites.setReminder(value, for: s.id) } }
                    )) {
                        Label("Avisarme \(reminders.leadMinutes) min antes", systemImage: "bell")
                    }
                    .disabled(s.isCancelled)
                    if reminders.isDenied {
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        } label: {
                            Label("Notificaciones desactivadas. Abrir Ajustes", systemImage: "exclamationmark.triangle")
                        }
                        .foregroundStyle(.orange)
                    }
                }
                Button { Task { await addToCalendar(s, room: room) } } label: {
                    Label("Añadir al calendario", systemImage: "calendar.badge.plus")
                }
                ShareLink(item: URL(string: "evento://charla/\(s.id)")!,
                          subject: Text(s.title),
                          message: Text("\(s.title). \(Fmt.day(s.start, tz)), \(Fmt.range(s, tz)), \(room?.name ?? "")")) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Charla")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await favorites.toggle(s) } } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? Color.yellow : Color.accentColor)
                }
                .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
            }
        }
        .alert("Calendario", isPresented: Binding(
            get: { calendarMessage != nil },
            set: { if !$0 { calendarMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(calendarMessage ?? "")
        }
        .task { await reminders.refreshAuthorization() }
    }

    private func addToCalendar(_ s: Session, room: Room?) async {
        do {
            try await CalendarService.add(s, room: room, tz: store.tz)
            calendarMessage = "Charla añadida a tu calendario."
        } catch {
            calendarMessage = error.localizedDescription
        }
    }
}
