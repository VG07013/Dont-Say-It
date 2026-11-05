import SwiftUI

struct HandoffView: View {
    let game: Game

    var body: some View {
        ZStack {
            game.currentTeam.color.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("TURN \(game.turnNumber)")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1)
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(game.teams) { team in
                            Text("\(team.name) \(team.score)")
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.ink.opacity(0.12), in: Capsule())
                        }
                    }
                }
                .frame(height: 44)

                Spacer()

                Image(systemName: "iphone")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(game.currentTeam.color)
                    .frame(width: 72, height: 72)
                    .background(Theme.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text("\(game.currentTeam.name),\nyou're up.")
                    .font(Theme.display(52))
                    .tracking(-1.2)
                    .lineSpacing(-4)
                    .minimumScaleFactor(0.6)

                Text("Pick one clue giver and hand them the phone. Everyone else on the team guesses.")
                    .font(.system(size: 17))
                    .lineSpacing(4)
                    .frame(maxWidth: 300, alignment: .leading)

                Spacer()

                Button("I'm the clue giver") {
                    game.startTurn()
                }
                .buttonStyle(BigButtonStyle(fill: Theme.ink, text: Theme.paper))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}
