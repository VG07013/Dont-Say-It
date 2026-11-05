import SwiftUI

struct HomeView: View {
    let game: Game
    @State private var showingRules = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                CircleIconButton(systemName: "questionmark", label: "How to play") {
                    showingRules = true
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 24) {
                LogoMark(size: 80)
                VStack(alignment: .leading, spacing: -6) {
                    Text("Don't")
                    HStack(spacing: 14) {
                        Text("Say")
                        Text("It.").foregroundStyle(Theme.coral)
                    }
                }
                .font(Theme.display(64))
                .tracking(-1.5)
                .accessibilityElement(children: .combine)

                Text("Get your team to guess the word without saying the banned ones.")
                    .font(.system(size: 17))
                    .lineSpacing(4)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: 300, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(spacing: 16) {
                VoiceCheckRow(isOn: Binding(
                    get: { game.voiceCheckOn },
                    set: { game.setVoiceCheck($0) }
                ))

                Button {
                    game.newGame()
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(BigButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .sheet(isPresented: $showingRules) {
            HowToPlayView()
        }
    }
}

private struct VoiceCheckRow: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 16) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.lime)
                    .frame(width: 44, height: 44)
                    .background(Theme.track, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Voice Check")
                        .font(.system(size: 16, weight: .semibold))
                    Text("The phone listens and calls out banned words")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .tint(Theme.lime)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

struct CircleIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Theme.surface, in: Circle())
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Step {
        let icon: String
        let title: String
        let text: String
    }

    private let steps = [
        Step(icon: "person.2.fill", title: "Split into teams", text: "Two to four teams. Each turn, one person gives clues."),
        Step(icon: "text.bubble.fill", title: "Describe the word", text: "Get your team to say the word on the card before time runs out."),
        Step(icon: "nosign", title: "Don't say the banned words", text: "Saying one, or the word itself, costs a point."),
        Step(icon: "mic.fill", title: "Voice Check keeps it fair", text: "Turn it on and the phone listens for banned words.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                Text("How to play")
                    .font(Theme.display(28))
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Close") { dismiss() }
            }

            VStack(alignment: .leading, spacing: 24) {
                ForEach(steps, id: \.title) { step in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: step.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.coral)
                            .frame(width: 44, height: 44)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title).font(.system(size: 17, weight: .semibold))
                            Text(step.text).font(.system(size: 15)).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }

            Spacer()

            HStack(spacing: 24) {
                ScoreRule(icon: "checkmark", text: "Got it +1", color: Theme.lime)
                ScoreRule(icon: "arrow.right", text: "Skip 0", color: Theme.muted)
                ScoreRule(icon: "xmark", text: "Oops -1", color: Theme.coral)
            }
        }
        .padding(24)
        .padding(.top, 8)
        .foregroundStyle(Theme.paper)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.ink)
        .presentationDragIndicator(.visible)
    }
}

private struct ScoreRule: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
    }
}
