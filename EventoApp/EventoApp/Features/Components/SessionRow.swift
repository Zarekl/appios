import SwiftUI

struct Tag: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: Capsule())
    }
}

struct SessionRow: View {
    let session: Session
    var showsDay = false
    var overlaps = false
    @Environment(EventStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: store.track(session)?.color ?? "#8E8E93"))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                    .strikethrough(session.isCancelled)
                    .foregroundStyle(session.isCancelled ? Color.secondary : Color.primary)
                Text(meta)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                let names = store.speakers(session).map(\.name).joined(separator: ", ")
                if !names.isEmpty {
                    Text(names).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
                }
                if session.isCancelled || overlaps {
                    HStack(spacing: 6) {
                        if session.isCancelled { Tag(text: "Cancelada", color: .red) }
                        if overlaps { Tag(text: "Se solapa", color: .orange) }
                    }
                }
            }
            Spacer(minLength: 0)
            if favorites.isFavorite(session.id) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorita")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var meta: String {
        let tz = store.tz
        var parts: [String] = []
        if showsDay { parts.append(Fmt.shortDay(session.start, tz)) }
        parts.append(Fmt.range(session, tz))
        if let room = store.room(session) { parts.append(room.name) }
        return parts.joined(separator: " · ")
    }
}

struct SpeakerRow: View {
    let speaker: Speaker
    var body: some View {
        HStack(spacing: 12) {
            SpeakerAvatar(speaker: speaker)
            VStack(alignment: .leading, spacing: 2) {
                Text(speaker.name).font(.headline)
                Text("\(speaker.role), \(speaker.company)").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct StatusBadge: View {
    let session: Session
    let now: Date
    var body: some View {
        if session.isCancelled {
            Tag(text: "Cancelada", color: .red)
        } else if session.isLive(at: now) {
            Tag(text: "En curso", color: .green)
        } else if session.hasEnded(at: now) {
            Tag(text: "Terminada", color: .gray)
        } else {
            Tag(text: "Empieza \(Fmt.relative(session.start, now: now))", color: .blue)
        }
    }
}
