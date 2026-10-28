import SwiftUI

/// Cuadrícula por horas con una columna por sala; bloques proporcionales a la duración.
struct AgendaGridView: View {
    let sessions: [Session]
    let day: Date
    @Environment(EventStore.self) private var store
    @Environment(AppClock.self) private var clock
    @ScaledMetric private var hourHeight: CGFloat = 96
    private let columnWidth: CGFloat = 168
    private let timeColumn: CGFloat = 52
    private let header: CGFloat = 40

    var body: some View {
        let cal = ScheduleLogic.eventCalendar(store.tz)
        let rooms = store.schedule.rooms.filter { r in sessions.contains { $0.roomId == r.id } }
        let columns = Dictionary(uniqueKeysWithValues: rooms.enumerated().map { ($0.element.id, $0.offset) })
        let firstHour = sessions.map { cal.component(.hour, from: $0.start) }.min() ?? 9
        let lastHour = max(sessions.map { endHour(of: $0, cal) }.max() ?? 18, firstHour + 1)
        let width = timeColumn + CGFloat(rooms.count) * columnWidth
        let height = header + CGFloat(lastHour - firstHour) * hourHeight + 16

        TimelineView(.everyMinute) { context in
            let now = clock.now(context.date)
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    ForEach(firstHour...lastHour, id: \.self) { hour in
                        let lineY = header + CGFloat(hour - firstHour) * hourHeight
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: width, height: 0.5)
                            .offset(y: lineY)
                        Text(String(format: "%02d:00", hour))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .offset(x: 8, y: lineY + 3)
                            .accessibilityHidden(true)
                    }
                    ForEach(rooms) { room in
                        Text(room.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: columnWidth - 8, height: header)
                            .offset(x: timeColumn + CGFloat(columns[room.id] ?? 0) * columnWidth + 4)
                    }
                    ForEach(sessions) { session in
                        if let column = columns[session.roomId] {
                            NavigationLink(value: Route.session(session.id)) {
                                GridBlock(session: session, now: now)
                            }
                            .buttonStyle(.plain)
                            .frame(width: columnWidth - 6, height: max(blockHeight(session), 32))
                            .offset(x: timeColumn + CGFloat(column) * columnWidth + 3,
                                    y: yPosition(session.start, firstHour, cal))
                        }
                    }
                    if cal.isDate(now, inSameDayAs: day) {
                        let nowY = yPosition(now, firstHour, cal)
                        if nowY >= header && nowY <= height {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: width, height: 2)
                                .offset(y: nowY)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .frame(width: width, height: height, alignment: .topLeading)
            }
        }
    }

    private func endHour(of s: Session, _ cal: Calendar) -> Int {
        let c = cal.dateComponents([.hour, .minute], from: s.end)
        return (c.hour ?? 18) + ((c.minute ?? 0) > 0 ? 1 : 0)
    }

    private func yPosition(_ date: Date, _ firstHour: Int, _ cal: Calendar) -> CGFloat {
        let c = cal.dateComponents([.hour, .minute], from: date)
        return header + (CGFloat((c.hour ?? 0) - firstHour) + CGFloat(c.minute ?? 0) / 60) * hourHeight
    }

    private func blockHeight(_ s: Session) -> CGFloat {
        CGFloat(s.end.timeIntervalSince(s.start) / 3600) * hourHeight - 4
    }
}

struct GridBlock: View {
    let session: Session
    let now: Date
    @Environment(EventStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let color = Color(hex: store.track(session)?.color ?? "#8E8E93")
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 4) {
                Text(session.title)
                    .font(.caption.weight(.semibold))
                    .strikethrough(session.isCancelled)
                    .lineLimit(3)
                Spacer(minLength: 0)
                if favorites.isFavorite(session.id) {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                }
            }
            Text(Fmt.range(session, store.tz)).font(.caption2).foregroundStyle(.secondary)
            if session.isLive(at: now) && !session.isCancelled {
                Text("En curso").font(.caption2.bold()).foregroundStyle(color)
            }
        }
        .padding(.leading, 9)
        .padding([.top, .bottom, .trailing], 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(session.isCancelled ? 0.06 : 0.16), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 3).padding(.vertical, 4).padding(.leading, 2)
        }
        .opacity(session.hasEnded(at: now) ? 0.55 : 1)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.title), \(Fmt.range(session, store.tz)), \(store.room(session)?.name ?? "")")
        .accessibilityValue(favorites.isFavorite(session.id) ? "Favorita" : "")
    }
}
