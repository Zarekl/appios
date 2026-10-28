import SwiftUI

struct AgendaView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case list = "Lista"
        case grid = "Agenda"
        var id: Self { self }
    }

    @Environment(EventStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites
    @Environment(AppClock.self) private var clock
    @State private var mode: Mode = .list
    @State private var day: Date?
    @State private var filters = SessionFilters()
    @State private var query = ""
    @State private var showsFilters = false

    var body: some View {
        let days = store.days
        let selected = day ?? defaultDay(days)
        let sessions = filters.apply(
            to: ScheduleLogic.sessions(store.schedule.sessions, on: selected, in: store.tz),
            favorites: favorites.ids, query: query, speakers: store.speakersById)

        VStack(spacing: 0) {
            VStack(spacing: 8) {
                if days.count > 1 {
                    Picker("Día", selection: Binding(get: { selected }, set: { day = $0 })) {
                        ForEach(days, id: \.self) { d in Text(Fmt.shortDay(d, store.tz)).tag(d) }
                    }
                    .pickerStyle(.segmented)
                }
                Picker("Vista", selection: $mode) {
                    ForEach(Mode.allCases) { m in Text(m.rawValue).tag(m) }
                }
                .pickerStyle(.segmented)
                if !filters.isEmpty { FilterChips(filters: $filters) }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider()

            if sessions.isEmpty {
                if query.isEmpty {
                    ContentUnavailableView("Sin charlas", systemImage: "line.3.horizontal.decrease",
                                           description: Text("Ninguna charla de este día coincide con los filtros."))
                } else {
                    ContentUnavailableView.search(text: query)
                }
            } else {
                switch mode {
                case .list: AgendaListView(sessions: sessions, day: selected)
                case .grid: AgendaGridView(sessions: sessions, day: selected)
                }
            }
        }
        .navigationTitle("Agenda")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Charla o expositor")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsFilters = true } label: {
                    Label("Filtros", systemImage: filters.isEmpty
                          ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showsFilters) { FiltersSheet(filters: $filters) }
    }

    private func defaultDay(_ days: [Date]) -> Date {
        let cal = ScheduleLogic.eventCalendar(store.tz)
        let now = clock.now()
        return days.first { cal.isDate($0, inSameDayAs: now) } ?? days.first { $0 > now } ?? days.last ?? now
    }
}

/// Lista por franja horaria; en el día actual salta a la franja en curso.
struct AgendaListView: View {
    let sessions: [Session]
    let day: Date
    @Environment(EventStore.self) private var store
    @Environment(AppClock.self) private var clock

    var body: some View {
        let slots = Dictionary(grouping: sessions) { $0.start }
        let keys = slots.keys.sorted()
        ScrollViewReader { proxy in
            List {
                ForEach(keys, id: \.self) { start in
                    Section {
                        ForEach(slots[start] ?? []) { s in
                            NavigationLink(value: Route.session(s.id)) { SessionRow(session: s) }
                        }
                    } header: {
                        Text(Fmt.time(start, store.tz))
                    }
                    .id(start)
                }
            }
            .listStyle(.plain)
            .task(id: day) {
                let now = clock.now()
                guard ScheduleLogic.eventCalendar(store.tz).isDate(day, inSameDayAs: now),
                      let target = keys.last(where: { $0 <= now }) ?? keys.first else { return }
                try? await Task.sleep(for: .milliseconds(250))
                proxy.scrollTo(target, anchor: .top)
            }
        }
    }
}
