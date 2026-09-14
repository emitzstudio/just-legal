//
//  SpeechService.swift
//  LexIndia
//
//  Read Aloud for information pages, built on AVSpeechSynthesizer.
//  One page speaks at a time; the control shows play/pause/stop states.
//

import Foundation
import AVFoundation
import Observation

@Observable
final class SpeechService {
    /// Identity of the page currently being read, if any.
    private(set) var activeId: String?
    private(set) var isPaused: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private let relay = SpeechDelegateRelay()

    init() {
        synthesizer.delegate = relay
        relay.onFinish = { [weak self] in
            Task { @MainActor in
                self?.clear()
            }
        }
    }

    /// Starts reading a page, or toggles pause/resume when the same page
    /// is already active.
    func toggle(id: String, text: String) {
        if activeId == id {
            if isPaused {
                synthesizer.continueSpeaking()
                isPaused = false
            } else {
                synthesizer.pauseSpeaking(at: .word)
                isPaused = true
            }
            return
        }

        stop()
        activateAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-IN")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.1

        activeId = id
        isPaused = false
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        clear()
    }

    private func clear() {
        activeId = nil
        isPaused = false
    }

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("[LexIndia] Audio session error: \(error.localizedDescription)")
        }
    }
}

/// Delegate relay — AVSpeechSynthesizer calls back off the main actor.
private nonisolated final class SpeechDelegateRelay: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish?()
    }
}
