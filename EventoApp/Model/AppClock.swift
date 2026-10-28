import Foundation
import Observation

/// Reloj inyectable. En la app permite simular la hora del evento para probar «Ahora».
@MainActor @Observable
final class AppClock {
    var offset: TimeInterval = 0
    var isSimulated: Bool { offset != 0 }

    func now(_ real: Date = Date()) -> Date { real.addingTimeInterval(offset) }
    func simulate(_ date: Date?) { offset = date.map { $0.timeIntervalSinceNow } ?? 0 }
}
