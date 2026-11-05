import SwiftUI

struct RootView: View {
    @State private var game = Game()

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()

            switch game.phase {
            case .home:
                HomeView(game: game).transition(.opacity)
            case .setup:
                SetupView(game: game).transition(.move(edge: .trailing).combined(with: .opacity))
            case .handoff:
                HandoffView(game: game).transition(.opacity)
            case .playing:
                TurnView(game: game).transition(.opacity)
            case .recap:
                RecapView(game: game).transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .foregroundStyle(Theme.paper)
        .animation(.smooth(duration: 0.3), value: game.phase)
    }
}

#Preview {
    RootView()
}
