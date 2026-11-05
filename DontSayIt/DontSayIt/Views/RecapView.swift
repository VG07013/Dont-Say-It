import SwiftUI

struct RecapView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Time's up")
                (Text("\(game.currentTeam.name) got ")
                    + Text(pointsText).foregroundColor(game.turnPoints >= 0 ? Theme.lime : Theme.coral))
                    .font(Theme.display(40))
                    .tracking(-0.8)
                    .minimumScaleFactor(0.7)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(game.teams) { team in
                    ScoreTile(team: team, highlighted: team.id == game.currentTeam.id)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "This turn")
                if game.entries.isEmpty {
                    Text("No cards this turn.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(game.entries.enumerated()), id: \.element.id) { index, entry in
                                EntryRow(entry: entry)
                                if index < game.entries.count - 1 {
                                    Rectangle().fill(Theme.track).frame(height: 1)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line, lineWidth: 1))
                    }
                    .scrollIndicators(.hidden)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Button("Pass to \(game.nextTeam.name)") {
                    game.passToNextTeam()
                }
                .buttonStyle(BigButtonStyle())

                Button("End game") {
                    game.endGame()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var pointsText: String {
        game.turnPoints >= 0 ? "+\(game.turnPoints)" : "\(game.turnPoints)"
    }
}

private struct ScoreTile: View {
    let team: Team
    let highlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
            Text("\(team.score)")
                .font(Theme.display(36))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(highlighted ? team.color : Color.clear, lineWidth: 2)
        )
    }
}

private struct EntryRow: View {
    let entry: TurnEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(entry.card.word)
                .font(.system(size: 16, weight: .medium))
            Spacer()
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
        }
        .frame(height: 52)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch entry.outcome {
        case .gotIt: "checkmark"
        case .skipped: "arrow.right"
        case .oops: "xmark"
        }
    }

    private var color: Color {
        switch entry.outcome {
        case .gotIt: Theme.lime
        case .skipped: Theme.muted
        case .oops: Theme.coral
        }
    }

    private var detail: String {
        switch entry.outcome {
        case .gotIt: "Got it"
        case .skipped: "Skipped"
        case .oops(let said):
            if let said { "Said \u{201C}\(said.lowercased())\u{201D}" } else { "Oops" }
        }
    }
}
