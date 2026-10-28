import SwiftUI

struct FilterOption: Identifiable {
    let id: String
    let label: String
    var color: Color? = nil
}

struct FiltersSheet: View {
    @Binding var filters: SessionFilters
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section { Toggle("Solo favoritos", isOn: $filters.onlyFavorites) }
                OptionSection(title: "Track",
                              options: store.schedule.tracks.map { FilterOption(id: $0.id, label: $0.name, color: Color(hex: $0.color)) },
                              selection: $filters.tracks)
                OptionSection(title: "Sala",
                              options: store.schedule.rooms.map { FilterOption(id: $0.id, label: $0.name) },
                              selection: $filters.rooms)
                OptionSection(title: "Formato", options: store.formats.map { FilterOption(id: $0, label: $0) },
                              selection: $filters.formats)
                OptionSection(title: "Nivel", options: store.levels.map { FilterOption(id: $0, label: $0) },
                              selection: $filters.levels)
                OptionSection(title: "Idioma", options: store.languages.map { FilterOption(id: $0, label: $0) },
                              selection: $filters.languages)
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpiar") { filters = SessionFilters() }.disabled(filters.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct OptionSection: View {
    let title: String
    let options: [FilterOption]
    @Binding var selection: Set<String>

    var body: some View {
        Section(title) {
            ForEach(options) { option in
                Button {
                    if selection.contains(option.id) { selection.remove(option.id) } else { selection.insert(option.id) }
                } label: {
                    HStack {
                        if let color = option.color { Circle().fill(color).frame(width: 10, height: 10) }
                        Text(option.label).foregroundStyle(Color.primary)
                        Spacer()
                        if selection.contains(option.id) {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .accessibilityAddTraits(selection.contains(option.id) ? .isSelected : [])
            }
        }
    }
}

/// Filtros activos como chips quitables.
struct FilterChips: View {
    @Binding var filters: SessionFilters
    @Environment(EventStore.self) private var store

    private struct Chip: Identifiable {
        let id: String
        let label: String
        let remove: (inout SessionFilters) -> Void
    }

    private var chips: [Chip] {
        var result: [Chip] = []
        for id in filters.tracks.sorted() {
            result.append(Chip(id: "t-\(id)", label: store.tracksById[id]?.name ?? id) { _ = $0.tracks.remove(id) })
        }
        for id in filters.rooms.sorted() {
            result.append(Chip(id: "r-\(id)", label: store.roomsById[id]?.name ?? id) { _ = $0.rooms.remove(id) })
        }
        for v in filters.formats.sorted() { result.append(Chip(id: "f-\(v)", label: v) { _ = $0.formats.remove(v) }) }
        for v in filters.levels.sorted() { result.append(Chip(id: "n-\(v)", label: v) { _ = $0.levels.remove(v) }) }
        for v in filters.languages.sorted() { result.append(Chip(id: "i-\(v)", label: v) { _ = $0.languages.remove(v) }) }
        if filters.onlyFavorites {
            result.append(Chip(id: "fav", label: "Solo favoritos") { $0.onlyFavorites = false })
        }
        return result
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    Button { chip.remove(&filters) } label: {
                        HStack(spacing: 4) {
                            Text(chip.label)
                            Image(systemName: "xmark").font(.caption2.bold())
                        }
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quitar filtro \(chip.label)")
                }
                Button("Limpiar") { filters = SessionFilters() }.font(.footnote)
            }
        }
    }
}
