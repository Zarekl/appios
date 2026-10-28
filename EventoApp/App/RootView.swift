import SwiftUI

/// Cuatro pestañas, cada una con su propio NavigationStack.
struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            NavigationStack(path: $router.homePath) { HomeView().withRoutes() }
                .tabItem { Label("Inicio", systemImage: "house") }
                .tag(Router.Tab.home)
            NavigationStack(path: $router.agendaPath) { AgendaView().withRoutes() }
                .tabItem { Label("Agenda", systemImage: "calendar") }
                .tag(Router.Tab.agenda)
            NavigationStack(path: $router.speakersPath) { SpeakersView().withRoutes() }
                .tabItem { Label("Expositores", systemImage: "person.2") }
                .tag(Router.Tab.speakers)
            NavigationStack(path: $router.favoritesPath) { FavoritesView().withRoutes() }
                .tabItem { Label("Favoritos", systemImage: "star") }
                .tag(Router.Tab.favorites)
        }
    }
}

struct RouteView: View {
    let route: Route
    var body: some View {
        switch route {
        case .session(let id): SessionDetailView(sessionId: id)
        case .speaker(let id): SpeakerDetailView(speakerId: id)
        }
    }
}

extension View {
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { RouteView(route: $0) }
    }
}
