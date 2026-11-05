# Don't Say It (SwiftUI)

A full native rebuild of the party word game. Describe the word on the card without saying any of its banned words. Voice Check can listen and catch you.

## Open and run

1. Open `DontSayIt/DontSayIt.xcodeproj` in Xcode 16 or newer.
2. Pick your team under Signing & Capabilities.
3. Run on an iPhone. Voice Check needs a real device for the mic.

## What's in it

- `Game/Game.swift`: teams, turns, timer and scoring (Got it +1, Skip 0, Oops -1)
- `Game/VoiceCheck.swift`: on-device speech recognition that restarts itself between sessions
- `Game/WordMatcher.swift`: catches banned words plus plurals and verb forms
- `Game/Card.swift`: loads `Resources/cards.json` and deals without repeats until the deck runs out
- `Views/`: home, setup, hand-off, turn, recap
- `Resources/cards.json`: 100 cards, 5 banned words each

Requires iOS 17. The old Capacitor version is still in the repo root for reference.
