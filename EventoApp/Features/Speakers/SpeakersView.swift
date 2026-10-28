import SwiftUI

struct SpeakersView: View {
    @Environment(EventStore.self) private var store
    @State private var query = ""

    var body: some View {
        let speakers = store.schedule.speakers
            .filter { query.isEmpty || $0.name.localizedStandardContains(query) || $0.company.localizedStandardContains(query) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let groups = Dictionary(grouping: speakers) { Self.letter(for: $0.name) }
        let letters = groups.keys.sorted()

        ScrollViewReader { proxy in
            List {
                ForEach(letters, id: \.self) { letter in
                    Section(letter) {
                        ForEach(groups[letter] ?? []) { sp in
                            NavigationLink(value: Route.speaker(sp.id)) { SpeakerRow(speaker: sp) }
                        }
                    }
                    .id(letter)
                }
            }
            .listStyle(.plain)
            .overlay(alignment: .trailing) {
                if query.isEmpty && letters.count > 3 {
                    VStack(spacing: 3) {
                        ForEach(letters, id: \.self) { l in
                            Button(l) { withAnimation { proxy.scrollTo(l, anchor: .top) } }
                                .font(.caption2.bold())
                                .accessibilityLabel("Ir a la letra \(l)")
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
            .overlay {
                if speakers.isEmpty { ContentUnavailableView.search(text: query) }
            }
        }
        .navigationTitle("Expositores")
        .searchable(text: $query, prompt: "Nombre o empresa")
    }

    static func letter(for name: String) -> String {
        String(name.folding(options: .diacriticInsensitive, locale: Fmt.locale).prefix(1)).uppercased()
    }
}

struct SpeakerDetailView: View {
    let speakerId: String
    @Environment(EventStore.self) private var store

    var body: some View {
        if let sp = store.speakersById[speakerId] {
            List {
                Section {
                    VStack(spacing: 10) {
                        SpeakerAvatar(speaker: sp, size: 96)
                        Text(sp.name).font(.title2.bold()).multilineTextAlignment(.center)
                        Text("\(sp.role), \(sp.company)").foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
                Section("Biografía") { Text(sp.bio) }
                if !sp.links.isEmpty {
                    Section("Enlaces") {
                        ForEach(sp.links, id: \.url) { link in
                            Link(destination: link.url) { Label(link.label, systemImage: "link") }
                        }
                    }
                }
                Section("Charlas") {
                    ForEach(store.sessionsBySpeaker[sp.id] ?? []) { s in
                        NavigationLink(value: Route.session(s.id)) { SessionRow(session: s, showsDay: true) }
                    }
                }
            }
            .navigationTitle(sp.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Expositor no encontrado", systemImage: "person.crop.circle.badge.questionmark")
        }
    }
}
