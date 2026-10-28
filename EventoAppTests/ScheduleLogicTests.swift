import XCTest
@testable import EventoApp

/// Pruebas de la lógica más propensa a fallos: horarios, solapamientos y filtros.
final class ScheduleLogicTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func session(_ id: String, _ startMin: Double, _ endMin: Double,
                         track: String = "dev", cancelled: Bool = false) -> Session {
        Session(id: id, title: id, abstract: "",
                start: base.addingTimeInterval(startMin * 60), end: base.addingTimeInterval(endMin * 60),
                roomId: "r1", trackId: track, speakerIds: [], format: "Charla", level: "Básico",
                language: "Español", updatedAt: base, cancelled: cancelled)
    }

    func testNowAndNext() {
        let all = [session("a", 0, 60), session("b", 45, 90), session("c", 120, 150), session("x", 50, 70, cancelled: true)]
        let now = base.addingTimeInterval(30 * 60)
        XCTAssertEqual(ScheduleLogic.live(all, at: now).map(\.id), ["a"])
        XCTAssertEqual(ScheduleLogic.upcoming(all, at: now).map(\.id), ["b"])   // c empieza en 90 min; x cancelada
        XCTAssertEqual(ScheduleLogic.next(all, after: base.addingTimeInterval(100 * 60))?.id, "c")
    }

    func testPhase() {
        let all = [session("a", 0, 60)]
        XCTAssertEqual(ScheduleLogic.phase(of: all, at: base.addingTimeInterval(-60)), .before(base))
        XCTAssertEqual(ScheduleLogic.phase(of: all, at: base.addingTimeInterval(60)), .during)
        XCTAssertEqual(ScheduleLogic.phase(of: all, at: base.addingTimeInterval(3600)), .after)
    }

    func testOverlaps() {
        let all = [session("a", 0, 60), session("b", 30, 90), session("c", 90, 120), session("d", 200, 230)]
        XCTAssertEqual(ScheduleLogic.overlappingIds(all), ["a", "b"])   // b termina justo cuando empieza c
    }

    func testCombinedFilters() {
        let all = [session("a", 0, 60, track: "dev"), session("b", 0, 60, track: "data"), session("c", 0, 60, track: "dev")]
        var f = SessionFilters()
        f.tracks = ["dev"]
        f.onlyFavorites = true
        XCTAssertEqual(f.apply(to: all, favorites: ["c", "b"], query: "", speakers: [:]).map(\.id), ["c"])
    }

    @MainActor
    func testBundledAgendaIsValid() throws {
        let schedule = SyncService.bundled()
        XCTAssertFalse(schedule.sessions.isEmpty)
        XCTAssertNoThrow(try schedule.validate())
    }
}
