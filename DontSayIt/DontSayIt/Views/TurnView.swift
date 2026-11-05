import SwiftUI

struct TurnView: View {
    let game: Game

    var body: some View {
        VStack(spacing: 24) {
            header
            timer

            ZStack {
                if let caught = game.caught {
                    CaughtCard(caught: caught)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                } else if let card = game.card {
                    WordCard(card: card)
                        .id(card.word)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .frame(maxHeight: .infinity)
            .animation(.smooth(duration: 0.28), value: game.card?.word)
            .animation(.spring(duration: 0.35, bounce: 0.3), value: game.caught)

            if game.caught != nil {
                Button {
                    game.dismissCatch()
                } label: {
                    Label("Next card", systemImage: "arrow.right")
                        .labelStyle(TrailingIconLabelStyle())
                }
                .buttonStyle(BigButtonStyle(fill: Theme.paper))
            } else {
                actions
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .sensoryFeedback(.success, trigger: game.gotCount)
        .sensoryFeedback(.error, trigger: game.oopsCount)
    }

    private var header: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "xmark", label: "End turn") {
                game.endTurn()
            }
            Text("\(game.currentTeam.name) · \(game.turnPoints >= 0 ? "+" : "")\(game.turnPoints)")
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .contentTransition(.numericText())
            Spacer()
            if game.voiceCheckOn {
                ListeningPill(status: game.voiceStatus)
            }
        }
        .frame(height: 44)
    }

    private var timer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Self.clock(game.timeLeft))
                .font(Theme.display(48))
                .monospacedDigit()
                .foregroundStyle(game.timeLeft <= 10 ? Theme.coral : Theme.paper)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: game.timeLeft)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule()
                        .fill(game.timeLeft <= 10 ? Theme.coral : Theme.paper)
                        .frame(width: proxy.size.width * progress)
                        .animation(.linear(duration: 0.2), value: game.timeLeft)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.timeLeft) seconds left")
    }

    private var actions: some View {
        HStack(spacing: 8) {
            ActionButton(title: "Skip", icon: "arrow.right", fill: Theme.surface, text: Theme.paper, outlined: true) {
                game.skip()
            }
            ActionButton(title: "Oops", icon: "xmark", fill: Theme.coral, text: Theme.ink) {
                game.oops()
            }
            ActionButton(title: "Got it", icon: "checkmark", fill: Theme.lime, text: Theme.ink, emphasized: true) {
                game.gotIt()
            }
        }
    }

    private var progress: CGFloat {
        guard game.turnLength > 0 else { return 0 }
        return CGFloat(game.timeLeft) / CGFloat(game.turnLength)
    }

    static func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct WordCard: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("GET THEM TO SAY")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.cardLabel)
                Text(card.word)
                    .font(Theme.display(52))
                    .tracking(-1.2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }

            Rectangle().fill(Theme.paperLine).frame(height: 1)

            VStack(alignment: .leading, spacing: 16) {
                Text("DON'T SAY")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.bannedLabel)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(card.banned, id: \.self) { word in
                        Text(word).font(.system(size: 22, weight: .semibold))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct CaughtCard: View {
    let caught: Catch

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.coral)
                .frame(width: 64, height: 64)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text("You said it.")
                    .font(Theme.display(52))
                    .tracking(-1.2)
                Text("Voice Check caught \u{201C}\(caught.word)\u{201D}.")
                    .font(.system(size: 17))
            }

            if !caught.heard.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT IT HEARD")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.muted)
                    Text("\u{201C}\(caught.heard)\u{201D}")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.paper)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            Spacer(minLength: 0)

            Text("-1 point")
                .font(Theme.display(28))
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.coral, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let fill: Color
    let text: Color
    var outlined = false
    var emphasized = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: emphasized ? 20 : 18, weight: .bold))
                Text(title)
                    .font(.system(size: emphasized ? 16 : 14, weight: emphasized ? .bold : .semibold))
            }
            .foregroundStyle(text)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(outlined ? Theme.line : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

private struct ListeningPill: View {
    let status: VoiceCheck.Status

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .symbolEffect(.pulse, isActive: status == .listening)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }

    private var text: String {
        switch status {
        case .listening: "Listening"
        case .starting: "Starting"
        case .denied: "Mic off"
        case .unavailable, .off: "Not listening"
        }
    }

    private var icon: String {
        switch status {
        case .listening, .starting: "mic.fill"
        case .denied, .unavailable, .off: "mic.slash.fill"
        }
    }

    private var color: Color {
        status == .listening ? Theme.lime : Theme.muted
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.title
            configuration.icon
        }
    }
}
