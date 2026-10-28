import Foundation

struct SessionFilters: Equatable {
    var tracks: Set<String> = []
    var rooms: Set<String> = []
    var formats: Set<String> = []
    var levels: Set<String> = []
    var languages: Set<String> = []
    var onlyFavorites = false

    var isEmpty: Bool {
        tracks.isEmpty && rooms.isEmpty && formats.isEmpty && levels.isEmpty && languages.isEmpty && !onlyFavorites
    }

    /// Los filtros se combinan (Y entre grupos, O dentro de cada grupo).
    func apply(to sessions: [Session], favorites: Set<String>, query: String, speakers: [String: Speaker]) -> [Session] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return sessions.filter { s in
            if !tracks.isEmpty && !tracks.contains(s.trackId) { return false }
            if !rooms.isEmpty && !rooms.contains(s.roomId) { return false }
            if !formats.isEmpty && !formats.contains(s.format) { return false }
            if !levels.isEmpty && !levels.contains(s.level) { return false }
            if !languages.isEmpty && !languages.contains(s.language) { return false }
            if onlyFavorites && !favorites.contains(s.id) { return false }
            if !q.isEmpty && !Self.matches(s, q, speakers) { return false }
            return true
        }
    }

    static func matches(_ s: Session, _ q: String, _ speakers: [String: Speaker]) -> Bool {
        if s.title.localizedStandardContains(q) { return true }
        return s.speakerIds.contains { speakers[$0]?.name.localizedStandardContains(q) ?? false }
    }
}
