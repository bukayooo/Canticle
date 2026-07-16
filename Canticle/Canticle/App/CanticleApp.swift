import SwiftUI

@main
struct CanticleApp: App {
    @State private var isSplashVisible = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if isSplashVisible {
                    SplashView { isSplashVisible = false }
                        .zIndex(1)
                }
            }
            .preferredColorScheme(nil) // follow system; theme adapts light/dark
        }
    }
}
