import SwiftUI

struct SetupView: View {
    @Bindable var game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 16) {
                CircleIconButton(systemName: "chevron.left", label: "Back") {
                    game.endGame()
                }
                Text("New game")
                    .font(Theme.display(28))
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Teams")
                        ForEach($game.teams) { $team in
                            TeamRow(team: $team, canRemove: game.canRemoveTeam) {
                                withAnimation(.smooth) { game.removeTeam(team) }
                            }
                        }
                        if game.canAddTeam {
                            Button {
                                withAnimation(.smooth) { game.addTeam() }
                            } label: {
                                Label("Add a team", systemImage: "plus")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.muted)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .strokeBorder(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Time per turn")
                        TimePicker(selection: $game.turnLength)
                    }
                }
            }
            .scrollIndicators(.hidden)

            Button("Start game") {
                game.startGame()
            }
            .buttonStyle(BigButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

private struct TeamRow: View {
    @Binding var team: Team
    let canRemove: Bool
    let onRemove: () -> Void
    @FocusState private var editing: Bool

    var body: some View {
        HStack(spacing: 16) {
            TeamBadge(team: team)
            TextField("Team name", text: $team.name)
                .font(.system(size: 17, weight: .semibold))
                .focused($editing)
                .submitLabel(.done)
                .textInputAutocapitalization(.words)
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(team.name)")
            } else {
                Button { editing = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rename \(team.name)")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(height: 72)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

private struct TimePicker: View {
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Game.turnLengths, id: \.self) { seconds in
                let selected = seconds == selection
                Button {
                    withAnimation(.snappy) { selection = seconds }
                } label: {
                    Text(Self.label(for: seconds))
                        .font(.system(size: 15, weight: selected ? .semibold : .medium))
                        .foregroundStyle(selected ? Theme.ink : Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? Theme.paper : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    static func label(for seconds: Int) -> String {
        seconds < 120 ? "\(seconds)s" : "\(seconds / 60)m"
    }
}
