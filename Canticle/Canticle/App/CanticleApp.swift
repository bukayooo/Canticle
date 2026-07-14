import SwiftUI

@main
struct CanticleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(nil) // follow system; theme adapts light/dark
        }
    }
}
