import AVFoundation
import Speech

/// Listens to the clue giver during a turn and hands back what it hears as words.
/// Speech sessions end on their own every so often, so this quietly restarts them.
@MainActor
final class VoiceCheck {
    enum Status: Equatable {
        case off
        case starting
        case listening
        case denied
        case unavailable
    }

    var onStatusChange: ((Status) -> Void)?
    /// Called with every word heard so far in the current speech session.
    var onWords: (([String]) -> Void)?
    /// Called when a new speech session starts and the word list begins again from empty.
    var onSessionStart: (() -> Void)?
    /// Words to help recognition, like the current card's word and banned words.
    var hints: [String] = []

    private(set) var status: Status = .off {
        didSet { if status != oldValue { onStatusChange?(status) } }
    }

    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var wantsToListen = false
    private var session = 0

    func start() async {
        guard !wantsToListen else { return }
        wantsToListen = true
        status = .starting

        guard await Self.requestPermissions() else {
            wantsToListen = false
            status = .denied
            return
        }
        guard wantsToListen else { return }

        do {
            try begin()
        } catch {
            wantsToListen = false
            status = .unavailable
        }
    }

    func stop() {
        wantsToListen = false
        session += 1
        tearDown()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        status = .off
    }

    // MARK: - Private

    private static func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authorization in
                continuation.resume(returning: authorization == .authorized)
            }
        }
        guard speechAllowed else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    private func begin() throws {
        tearDown()
        guard let recognizer, recognizer.isAvailable else { throw VoiceCheckError.unavailable }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = hints
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        Self.installTap(on: engine.inputNode, feeding: request)
        engine.prepare()
        try engine.start()

        session += 1
        let thisSession = session
        self.request = request
        onSessionStart?()

        task = recognizer.recognitionTask(with: request, resultHandler: Self.makeHandler { [weak self] words, finished in
            guard let self, self.session == thisSession else { return }
            if let words { self.onWords?(words) }
            if finished { self.restartSoon() }
        })

        status = .listening
    }

    private func restartSoon() {
        tearDown()
        guard wantsToListen else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard let self, self.wantsToListen else { return }
            do {
                try self.begin()
            } catch {
                self.wantsToListen = false
                self.status = .unavailable
            }
        }
    }

    private func tearDown() {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    /// The tap runs on the audio thread, so it is built outside the main actor.
    nonisolated private static func installTap(on input: AVAudioInputNode, feeding request: SFSpeechAudioBufferRecognitionRequest) {
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    /// Speech results arrive on a background queue; this hops them back to the main actor.
    nonisolated private static func makeHandler(
        _ deliver: @escaping @MainActor ([String]?, Bool) -> Void
    ) -> (SFSpeechRecognitionResult?, Error?) -> Void {
        { result, error in
            let words = result.map { WordMatcher.normalize($0.bestTranscription.formattedString) }
            let finished = error != nil || (result?.isFinal ?? false)
            Task { @MainActor in deliver(words, finished) }
        }
    }

    private enum VoiceCheckError: Error {
        case unavailable
    }
}
