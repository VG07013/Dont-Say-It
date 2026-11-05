import Foundation

/// Checks spoken words against a card's banned words, including
/// plurals and verb forms ("flipping" counts for "Flip").
enum WordMatcher {
    static func normalize(_ text: String) -> [String] {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }

    /// The first rule (banned word or the card's own word) found in the spoken words, if any.
    static func firstMatch(in spoken: [String], rules: [String]) -> String? {
        guard !spoken.isEmpty else { return nil }
        let spokenSet = Set(spoken)
        let joined = " " + spoken.joined(separator: " ") + " "

        for rule in rules {
            let parts = normalize(rule)
            guard let last = parts.last else { continue }

            if parts.count == 1 {
                if !spokenSet.isDisjoint(with: variants(of: last)) { return rule }
                continue
            }

            // Multi word rules like "Ice Cream": match the phrase, letting the last word bend ("hot dogs").
            let head = parts.dropLast().joined(separator: " ")
            for form in variants(of: last) where joined.contains(" \(head) \(form) ") {
                return rule
            }
            // Sometimes speech recognition writes it as one word ("icecream").
            if spokenSet.contains(parts.joined()) { return rule }
        }
        return nil
    }

    static func variants(of word: String) -> Set<String> {
        var forms: Set<String> = [word]
        if let extra = irregular[word] { forms.formUnion(extra) }

        forms.insert(word + "s")
        forms.insert(word + "es")
        forms.insert(word + "ed")
        forms.insert(word + "ing")
        forms.insert(word + "er")

        if word.hasSuffix("e") {
            let stem = String(word.dropLast())
            forms.insert(word + "d")
            forms.insert(word + "r")
            forms.insert(stem + "ing")
        }

        if word.hasSuffix("y"), word.count > 2 {
            let stem = String(word.dropLast())
            forms.insert(stem + "ies")
            forms.insert(stem + "ied")
        }

        if doublesFinalConsonant(word), let last = word.last {
            forms.insert(word + String(last) + "ing")
            forms.insert(word + String(last) + "ed")
            forms.insert(word + String(last) + "er")
        }

        // Banned words written as plurals ("Wings") should also catch the singular ("wing").
        if word.hasSuffix("ies"), word.count > 4 {
            forms.insert(String(word.dropLast(3)) + "y")
        } else if word.hasSuffix("es"), word.count > 4 {
            forms.insert(String(word.dropLast(2)))
            forms.insert(String(word.dropLast(1)))
        } else if word.hasSuffix("s"), !word.hasSuffix("ss"), word.count > 3 {
            forms.insert(String(word.dropLast()))
        }

        return forms
    }

    private static func doublesFinalConsonant(_ word: String) -> Bool {
        let letters = Array(word)
        guard letters.count >= 3 else { return false }
        let last = letters[letters.count - 1]
        let middle = letters[letters.count - 2]
        let first = letters[letters.count - 3]
        return !isVowel(last) && !"wxy".contains(last) && isVowel(middle) && !isVowel(first)
    }

    private static func isVowel(_ letter: Character) -> Bool {
        "aeiou".contains(letter)
    }

    private static let irregular: [String: [String]] = [
        "teeth": ["tooth"],
        "tooth": ["teeth"],
        "mouse": ["mice"],
        "leaves": ["leaf"],
        "leaf": ["leaves"],
        "knife": ["knives"],
        "child": ["children"],
        "fly": ["flew", "flown", "flies", "flying"],
        "swim": ["swam", "swum"],
        "ride": ["rode", "ridden"],
        "blow": ["blew", "blown"],
        "throw": ["threw", "thrown"],
        "grow": ["grew", "grown"],
        "wear": ["wore", "worn"],
        "fall": ["fell", "fallen"],
        "sleep": ["slept"],
        "build": ["built"],
        "fight": ["fought"],
        "frozen": ["freeze", "froze", "freezing"],
        "sting": ["stung"],
        "dive": ["dove"],
        "bite": ["bitten"],
        "breathe": ["breath"],
        "eight": ["eighth"]
    ]
}
