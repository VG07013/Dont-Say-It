import SwiftUI

enum Theme {
    static let ink = Color(hex: 0x15131F)
    static let surface = Color(hex: 0x221F30)
    static let line = Color(hex: 0x3A3550)
    static let track = Color(hex: 0x2C2840)
    static let paper = Color(hex: 0xF6F2EA)
    static let paperLine = Color(hex: 0xDDD6C8)
    static let muted = Color(hex: 0xB5AFC4)
    static let coral = Color(hex: 0xFF6B57)
    static let lime = Color(hex: 0xD7F75B)
    static let sky = Color(hex: 0x7CC8FF)
    static let lilac = Color(hex: 0xC9A7FF)
    static let cardLabel = Color(hex: 0x5C566E)
    static let bannedLabel = Color(hex: 0xB23A2A)

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The big filled button used for the main action on each screen.
struct BigButtonStyle: ButtonStyle {
    var fill: Color = Theme.coral
    var text: Color = Theme.ink
    var height: CGFloat = 64

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(20))
            .foregroundStyle(text)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Outlined button for the quieter choice next to a big button.
struct OutlineButtonStyle: ButtonStyle {
    var selected = false
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: selected ? .semibold : .medium))
            .foregroundStyle(selected ? Theme.ink : Theme.paper)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? Theme.paper : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Color.clear : Theme.line, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Theme.muted)
    }
}

struct TeamBadge: View {
    let team: Team
    var size: CGFloat = 40

    var body: some View {
        Text(team.initial)
            .font(Theme.display(size * 0.5))
            .foregroundStyle(Theme.ink)
            .frame(width: size, height: size)
            .background(team.color, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

/// The app's mark: a speech bubble with an X through it.
struct LogoMark: View {
    var size: CGFloat = 88
    var bubble: Color = Theme.coral
    var mark: Color = Theme.ink

    var body: some View {
        ZStack {
            BubbleShape().fill(bubble)
            XShape()
                .stroke(mark, style: StrokeStyle(lineWidth: size * 8.5 / 88, lineCap: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Drawn on an 88 by 88 grid so it matches the app icon.
private struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let unit = min(rect.width, rect.height) / 88
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * unit, y: rect.minY + y * unit)
        }
        var path = Path()
        path.addRoundedRect(
            in: CGRect(origin: point(6, 6), size: CGSize(width: 76 * unit, height: 56 * unit)),
            cornerSize: CGSize(width: 16 * unit, height: 16 * unit),
            style: .continuous
        )
        path.move(to: point(20, 56))
        path.addLine(to: point(42, 56))
        path.addLine(to: point(18, 80))
        path.closeSubpath()
        return path
    }
}

private struct XShape: Shape {
    func path(in rect: CGRect) -> Path {
        let unit = min(rect.width, rect.height) / 88
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * unit, y: rect.minY + y * unit)
        }
        var path = Path()
        path.move(to: point(31, 21))
        path.addLine(to: point(57, 47))
        path.move(to: point(57, 21))
        path.addLine(to: point(31, 47))
        return path
    }
}
