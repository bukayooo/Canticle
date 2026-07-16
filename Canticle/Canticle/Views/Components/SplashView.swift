import SwiftUI

/// A brief in-app continuation of the native launch screen (gold `AccentColor` background,
/// crimson cross - see `Assets.xcassets/LaunchCross` and `project.yml`'s `UILaunchScreen`). Colors
/// match exactly so the hand-off from the OS-rendered launch screen to this view is seamless; a
/// per-app-icon color scheme was tried and rejected because the native launch screen can never be
/// dynamic (it's rendered before any app code runs), so any splash color other than the native
/// screen's fixed gold produced a jarring flash at hand-off. After a short hold, the cross expands
/// and the whole view fades away into `ContentView`.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var crossScale: CGFloat = 1
    @State private var opacity: Double = 1

    private let holdDuration: Duration = .seconds(2.1)
    private let transitionDuration: Double = 0.45

    var body: some View {
        Theme.gold
            .ignoresSafeArea()
            .overlay {
                CrusaderCrossShape()
                    .fill(Theme.crimson)
                    .frame(width: 120, height: 120)
                    .scaleEffect(crossScale)
            }
            .opacity(opacity)
            .task {
                try? await Task.sleep(for: holdDuration)
                withAnimation(.easeIn(duration: transitionDuration)) {
                    crossScale = 9
                    opacity = 0
                }
                try? await Task.sleep(for: .seconds(transitionDuration))
                onFinished()
            }
    }
}

#Preview {
    SplashView(onFinished: {})
}
