import Foundation
import SwiftUI

/// Formatos de fecha siempre en la zona horaria del evento, no la del teléfono.
enum Fmt {
    static let locale = Locale(identifier: "es_EC")
    private static var cache: [String: DateFormatter] = [:]

    private static func formatter(_ format: String, _ tz: TimeZone) -> DateFormatter {
        let key = format + "|" + tz.identifier
        if let f = cache[key] { return f }
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = tz
        f.dateFormat = format
        cache[key] = f
        return f
    }

    static func time(_ d: Date, _ tz: TimeZone) -> String { formatter("HH:mm", tz).string(from: d) }

    static func day(_ d: Date, _ tz: TimeZone) -> String {
        let s = formatter("EEEE d 'de' MMMM", tz).string(from: d)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    static func shortDay(_ d: Date, _ tz: TimeZone) -> String {
        let s = formatter("EEE d", tz).string(from: d).replacingOccurrences(of: ".", with: "")
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    static func range(_ s: Session, _ tz: TimeZone) -> String { "\(time(s.start, tz))–\(time(s.end, tz))" }

    static func relative(_ d: Date, now: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = locale
        f.unitsStyle = .full
        return f.localizedString(for: d, relativeTo: now)
    }
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}
