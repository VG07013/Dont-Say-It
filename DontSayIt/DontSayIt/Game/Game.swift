import SwiftUI
import Observation

struct Team: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var score = 0
    var colorIndex: Int

    var color: Color { Team.palette[colorIndex % Team.palette.count] }
    var initial: String { name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?" }

    static let palette: [Color] = [Theme.coral, Theme.lime, Theme.sky, Theme.lilac]
    static let suggestedNames = ["Hot Sauce", "Big Brains", "Night Owls", "Wild Cards"]
    static let maxTeams = 4
}

struct TurnEntry: Identifiable {
    enum Outcome: Equatable {
        case gotIt
        case skipped
        case oops(said: String?)
    }

    let id = UUID()
    let card: Card
    let outcome: Outcome
}

struct Catch: Equatable {
    let word: String
    let heard: String
}

@MainActor
@Observable
final class Game {
    enum Phase {
        case home
        case setup
        case handoff
        case playing
        case recap
    }

    static let turnLengths = [30, 60, 90, 120]

    var phase: Phase = .home
    var teams: [Team] = [
        Team(name: Team.suggestedNames[0], colorIndex: 0),
        Team(name: Team.suggestedNames[1], colorIndex: 1)
    ]
    var turnLength = 60
    private(set) var voiceCheckOn: Bool

    private(set) var currentTeamIndex = 0
    private(set) var turnNumber = 1
    private(set) var card: Card?
    private(set) var entries: [TurnEntry] = []
    private(set) var timeLeft = 60
    private(set) var caught: Catch?
    private(set) var voiceStatus: VoiceCheck.Status = .off

    @ObservationIgnored private var deck = Deck()
    @ObservationIgnored private let voice = VoiceCheck()
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var heardWords: [String] = []
    @ObservationIgnored private var checkedUpTo = 0

    private static let voiceCheckKey = "settings.voiceCheck"

    init() {
        let defaults = UserDefaults.standard
        voiceCheckOn = defaults.object(forKey: Self.voiceCheckKey) as? Bool ?? true

        voice.onStatusChange = { [weak self] status in self?.voiceStatus = status }
        voice.onWords = { [weak self] words in self?.hear(words) }
        voice.onSessionStart = { [weak self] in
            self?.heardWords = []
            self?.checkedUpTo = 0
        }
    }

    // MARK: - Derived

    var currentTeam: Team { teams[currentTeamIndex] }
    var nextTeam: Team { teams[(currentTeamIndex + 1) % teams.count] }
    var turnPoints: Int { entries.reduce(0) { $0 + Self.points(for: $1.outcome) } }
    var gotCount: Int { entries.filter { $0.outcome == .gotIt }.count }
    var oopsCount: Int { entries.filter { if case .oops = $0.outcome { return true } else { return false } }.count }
    var canAddTeam: Bool { teams.count < Team.maxTeams }
    var canRemoveTeam: Bool { teams.count > 2 }

    // MARK: - Setup

    func setVoiceCheck(_ on: Bool) {
        voiceCheckOn = on
        UserDefaults.standard.set(on, forKey: Self.voiceCheckKey)
    }

    func newGame() {
        phase = .setup
    }

    func addTeam() {
        guard canAddTeam else { return }
        let used = Set(teams.map(\.colorIndex))
        let color = (0..<Team.palette.count).first { !used.contains($0) } ?? teams.count
        let name = Team.suggestedNames.first { suggested in !teams.contains { $0.name == suggested } } ?? "Team \(teams.count + 1)"
        teams.append(Team(name: name, colorIndex: color))
    }

    func removeTeam(_ team: Team) {
        guard canRemoveTeam else { return }
        teams.removeAll { $0.id == team.id }
    }

    func startGame() {
        for index in teams.indices {
            if teams[index].name.trimmingCharacters(in: .whitespaces).isEmpty {
                teams[index].name = "Team \(index + 1)"
            }
            teams[index].score = 0
        }
        currentTeamIndex = 0
        turnNumber = 1
        phase = .handoff
    }

    // MARK: - Turn

    func startTurn() {
        entries = []
        caught = nil
        timeLeft = turnLength
        dealCard()
        phase = .playing
        UIApplication.shared.isIdleTimerDisabled = true
        startTimer()
        if voiceCheckOn {
            Task { await voice.start() }
        }
    }

    func gotIt() { record(.gotIt) }
    func skip() { record(.skipped) }
    func oops() { record(.oops(said: nil)) }

    func dismissCatch() {
        guard caught != nil else { return }
        caught = nil
        dealCard()
    }

    func endTurn() {
        timerTask?.cancel()
        timerTask = nil
        voice.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        caught = nil
        teams[currentTeamIndex].score += turnPoints
        phase = .recap
    }

    func passToNextTeam() {
        currentTeamIndex = (currentTeamIndex + 1) % teams.count
        turnNumber += 1
        phase = .handoff
    }

    func endGame() {
        timerTask?.cancel()
        voice.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        phase = .home
    }

    // MARK: - Private

    private static func points(for outcome: TurnEntry.Outcome) -> Int {
        switch outcome {
        case .gotIt: 1
        case .skipped: 0
        case .oops: -1
        }
    }

    private func record(_ outcome: TurnEntry.Outcome) {
        guard phase == .playing, caught == nil, let card else { return }
        entries.append(TurnEntry(card: card, outcome: outcome))
        dealCard()
    }

    private func dealCard() {
        card = deck.next()
        checkedUpTo = heardWords.count
        if let card { voice.hints = [card.word] + card.banned }
    }

    private func startTimer() {
        timerTask?.cancel()
        let end = Date.now.addingTimeInterval(TimeInterval(turnLength))
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                let remaining = Int(ceil(end.timeIntervalSinceNow))
                guard let self else { return }
                self.timeLeft = max(0, remaining)
                if remaining <= 0 {
                    self.endTurn()
                    return
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func hear(_ words: [String]) {
        heardWords = words
        guard phase == .playing, caught == nil, let card else { return }
        if checkedUpTo > words.count { checkedUpTo = 0 }

        let fresh = Array(words[checkedUpTo...])
        guard let hit = WordMatcher.firstMatch(in: fresh, rules: [card.word] + card.banned) else { return }

        checkedUpTo = words.count
        caught = Catch(word: hit, heard: fresh.suffix(12).joined(separator: " "))
        entries.append(TurnEntry(card: card, outcome: .oops(said: hit)))
    }
}
