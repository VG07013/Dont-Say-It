import AVFoundation
import Capacitor
import Speech

@objc(NativeSpeechPlugin)
class NativeSpeechPlugin: CAPPlugin, CAPBridgedPlugin {
    let identifier = "NativeSpeechPlugin"
    let jsName = "NativeSpeech"
    let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise)
    ]

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var shouldKeepListening = false
    private var isStarting = false

    @objc func start(_ call: CAPPluginCall) {
        guard !isStarting else {
            call.resolve()
            return
        }

        shouldKeepListening = true
        isStarting = true

        requestSpeechPermission { [weak self] speechAllowed in
            guard let self = self else { return }

            guard speechAllowed else {
                self.isStarting = false
                self.shouldKeepListening = false
                self.notifyListeners("speechError", data: ["message": "Speech recognition permission was denied."])
                call.reject("Speech recognition permission was denied.")
                return
            }

            self.requestMicrophonePermission { micAllowed in
                guard micAllowed else {
                    self.isStarting = false
                    self.shouldKeepListening = false
                    self.notifyListeners("speechError", data: ["message": "Microphone permission was denied."])
                    call.reject("Microphone permission was denied.")
                    return
                }

                DispatchQueue.main.async {
                    do {
                        try self.beginRecognition()
                        self.isStarting = false
                        call.resolve()
                    } catch {
                        self.isStarting = false
                        self.shouldKeepListening = false
                        self.notifyListeners("speechError", data: ["message": error.localizedDescription])
                        call.reject(error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc func stop(_ call: CAPPluginCall) {
        shouldKeepListening = false
        stopRecognition()
        notifyListeners("speechStatus", data: ["listening": false])
        call.resolve()
    }

    override func load() {
        super.load()
        notifyListeners("speechStatus", data: ["available": speechRecognizer != nil])
    }

    private func requestSpeechPermission(_ completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(status == .authorized)
        }
    }

    private func requestMicrophonePermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            completion(allowed)
        }
    }

    private func beginRecognition() throws {
        stopRecognition()

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.unavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionRequest = request
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcript = result.bestTranscription.formattedString
                self.notifyListeners("speechResult", data: ["transcript": transcript])
            }

            if error != nil || result?.isFinal == true {
                self.stopRecognition()

                if self.shouldKeepListening {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        guard self.shouldKeepListening else { return }
                        do {
                            try self.beginRecognition()
                        } catch {
                            self.shouldKeepListening = false
                            self.notifyListeners("speechError", data: ["message": error.localizedDescription])
                        }
                    }
                }
            }
        }

        notifyListeners("speechStatus", data: ["listening": true])
    }

    private func stopRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }

    enum SpeechError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "Speech recognition is not available right now."
        }
    }
}
