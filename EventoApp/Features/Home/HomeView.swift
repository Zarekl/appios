import SwiftUI

/// Lo que está pasando ahora y lo que viene. Se refresca cada minuto sin tocar la red.
struct HomeView: View {
    @Environment(EventStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites
    @Environment(AppClock.self) private var clock
    @Environment(SyncService.self) private var sync
    @Environment(Router.self) private var router
    @State private var showsClock = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(now: clock.now(context.date))
        }
        .navigationTitle("Inicio")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsClock = true } label: {
                    Image(systemName: clock.isSimulated ? "clock.badge.exclamationmark.fill" : "clock")
                }
                .accessibilityLabel("Simular hora")
            }
        }
        .sheet(isPresented: $showsClock) { SimulatedClockSheet() }
    }

    private func content(now: Date) -> some View {
        let tz = store.tz
        let sessions = store.schedule.sessions
        let phase = ScheduleLogic.phase(of: sessions, at: now)
        let live = ScheduleLogic.live(sessions, at: now)
        let upcoming = ScheduleLogic.upcoming(sessions, at: now)

        return List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("⭐️ \(store.schedule.event.name)").font(.title2.bold())
                    Text(store.schedule.event.venue).foregroundStyle(.secondary)
                    SyncStatusLabel().font(.caption)
                    if clock.isSimulated {
                        Label("Hora simulada: \(Fmt.shortDay(now, tz)), \(Fmt.time(now, tz))",
                              systemImage: "clock.badge.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }

            switch phase {
            case .before(let start):
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("El evento empieza").foregroundStyle(.secondary)
                        Text(Fmt.relative(start, now: now)).font(.largeTitle.bold())
                        Text("\(Fmt.day(start, tz)), \(Fmt.time(start, tz))").foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    Button("Ver la agenda") { router.tab = .agenda }
                }
            case .after:
                Section {
                    ContentUnavailableView("Gracias por venir", systemImage: "hands.clap",
                                           description: Text("El evento ha terminado. La agenda y tus favoritos siguen disponibles."))
                }
            case .during:
                Section("Ahora") {
                    if live.isEmpty {
                        Text("No hay charlas en este momento.").foregroundStyle(.secondary)
                    }
                    ForEach(live) { s in
                        NavigationLink(value: Route.session(s.id)) {
                            VStack(alignment: .leading, spacing: 8) {
                                SessionRow(session: s)
                                ProgressView(value: s.progress(at: now))
                                    .tint(Color(hex: store.track(s)?.color ?? "#8E8E93"))
                                    .accessibilityLabel("Progreso")
                                Text("Termina \(Fmt.relative(s.end, now: now))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("A continuación") {
                    if upcoming.isEmpty {
                        if let next = ScheduleLogic.next(sessions, after: now) {
                            NavigationLink(value: Route.session(next.id)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Próxima charla").font(.caption).foregroundStyle(.secondary)
                                    SessionRow(session: next, showsDay: true)
                                }
                            }
                        } else {
                            Text("No quedan más charlas.").foregroundStyle(.secondary)
                        }
                    }
                    ForEach(upcoming) { s in
                        NavigationLink(value: Route.session(s.id)) { SessionRow(session: s) }
                            .listRowBackground(favorites.isFavorite(s.id) ? Color.yellow.opacity(0.14) : nil)
                    }
                }
            }
        }
        .refreshable { await sync.refresh() }
    }
}

struct SyncStatusLabel: View {
    @Environment(SyncService.self) private var sync
    @Environment(EventStore.self) private var store
    @Environment(Connectivity.self) private var connectivity

    var body: some View {
        if !connectivity.isOnline {
            Label("Sin conexión. Usando la agenda guardada.", systemImage: "wifi.slash").foregroundStyle(.orange)
        } else {
            switch sync.status {
            case .syncing:
                Label("Actualizando…", systemImage: "arrow.triangle.2.circlepath").foregroundStyle(.secondary)
            case .offline:
                Label("Sin conexión. Usando la agenda guardada.", systemImage: "wifi.slash").foregroundStyle(.orange)
            case .failed:
                Label("No se pudo actualizar. Usando la agenda guardada.", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
            case .notConfigured, .idle:
                if let date = store.lastUpdated {
                    Label("Actualizado \(Fmt.relative(date, now: Date()))", systemImage: "checkmark.circle").foregroundStyle(.secondary)
                } else {
                    Label("Agenda incluida en la app", systemImage: "internaldrive").foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Herramienta de prueba: cambia la hora que ve la app (no la de los recordatorios).
struct SimulatedClockSheet: View {
    @Environment(AppClock.self) private var clock
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Fecha y hora", selection: $date)
                        .environment(\.timeZone, store.tz)
                } footer: {
                    Text("Solo cambia lo que muestra la app: Inicio y las etiquetas «En curso». Los recordatorios siguen la hora real.")
                }
                Section("Atajos") {
                    ForEach(store.days, id: \.self) { day in
                        Button("\(Fmt.day(day, store.tz)), 10:30") { date = day.addingTimeInterval(10.5 * 3600) }
                    }
                }
                Section {
                    Button("Usar la hora real", role: .destructive) {
                        clock.simulate(nil)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Simular hora")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        clock.simulate(date)
                        dismiss()
                    }
                }
            }
            .onAppear { date = clock.now() }
        }
        .presentationDetents([.medium, .large])
    }
}
