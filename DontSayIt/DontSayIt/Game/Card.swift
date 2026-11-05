import Foundation

struct Card: Codable, Hashable, Identifiable {
    let word: String
    let banned: [String]

    var id: String { word }
}

enum CardLibrary {
    /// Every card that ships with the app, loaded from cards.json.
    static let all: [Card] = {
        guard
            let url = Bundle.main.url(forResource: "cards", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let cards = try? JSONDecoder().decode([Card].self, from: data)
        else { return [] }
        return cards
    }()
}

/// Deals cards in a shuffled order that carries over between games,
/// so every card comes up once before any of them repeat.
struct Deck {
    private static let orderKey = "deck.order"
    private static let positionKey = "deck.position"

    private var order: [String]
    private var position: Int
    private let cardsByWord: [String: Card]

    init(cards: [Card] = CardLibrary.all) {
        var lookup: [String: Card] = [:]
        for card in cards { lookup[card.word] = card }
        cardsByWord = lookup

        let defaults = UserDefaults.standard
        let saved = defaults.stringArray(forKey: Self.orderKey) ?? []
        if !saved.isEmpty, Set(saved) == Set(lookup.keys) {
            order = saved
            position = defaults.integer(forKey: Self.positionKey)
        } else {
            order = cards.map(\.word).shuffled()
            position = 0
        }
    }

    mutating func next() -> Card? {
        guard !order.isEmpty else { return nil }
        if position >= order.count {
            order.shuffle()
            position = 0
        }
        let card = cardsByWord[order[position]]
        position += 1
        save()
        return card
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(order, forKey: Self.orderKey)
        defaults.set(position, forKey: Self.positionKey)
    }
}
