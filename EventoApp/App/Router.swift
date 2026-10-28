import Observation
import SwiftUI

enum Route: Hashable {
    case session(String)
    case speaker(String)
}

@MainActor @Observable
final class Router {
    enum Tab: Hashable { case home, agenda, speakers, favorites }

    var tab: Tab = .home
    var homePath = NavigationPath()
    var agendaPath = NavigationPath()
    var speakersPath = NavigationPath()
    var favoritesPath = NavigationPath()

    /// Abre la ruta en la pestaña actual, sin saltar de pestaña.
    func open(_ route: Route) {
        switch tab {
        case .home: homePath.append(route)
        case .agenda: agendaPath.append(route)
        case .speakers: speakersPath.append(route)
        case .favorites: favoritesPath.append(route)
        }
    }

    /// evento://charla/{id} · evento://expositor/{id}
    func handle(url: URL) {
        guard url.scheme == "evento", let id = url.pathComponents.dropFirst().first else { return }
        switch url.host() {
        case "charla": open(.session(id))
        case "expositor": open(.speaker(id))
        default: break
        }
    }
}
