import SwiftUI

@main @MainActor
struct EventApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private let env = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env.store)
                .environment(env.favorites)
                .environment(env.reminders)
                .environment(env.clock)
                .environment(env.router)
                .environment(env.sync)
                .environment(env.connectivity)
                .onOpenURL { env.router.handle(url: $0) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: Task { await env.refreshAll() }
            case .background: BackgroundRefresh.schedule()
            default: break
            }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await AppEnvironment.shared.backgroundRefresh()
        }
    }
}
