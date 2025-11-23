//
//  SoundEffects.swift
//  Stickers
//
//  Sound effects system for iOS and macOS using AVAudioEngine.
//  Provides various sound effects for user interactions.
//

import SwiftUI
import AVFoundation

#if os(macOS)
import AppKit
#endif

// MARK: - SoundEffects

/// Sound effects manager for iOS and macOS
/// Uses AVAudioEngine to generate synthesized sound effects
class SoundEffects {
    static let shared = SoundEffects()
    
    private var audioEngine: AVAudioEngine?
    private var audioSessionConfigured = false
    private var isEnabled: Bool = true
    private var lastSoundTime: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 0.05 // Minimum time between same sound type
    
    private init() {
        setupAudioEngine()
    }
    
    /// Setup the audio engine
    private func setupAudioEngine() {
        #if os(iOS)
        if !audioSessionConfigured {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                audioSessionConfigured = true
            } catch {
                print("Failed to configure audio session: \(error)")
            }
        }
        #endif
        
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else { return }
        
        // Connect mainMixerNode to outputNode to ensure the engine has an output
        let outputNode = engine.outputNode
        var format = outputNode.inputFormat(forBus: 0)
        if format.channelCount == 0 || format.sampleRate == 0 {
            // Fallback to a sane default if the output format looks invalid
            if let fallback = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) {
                format = fallback
            }
        }
        // Only disconnect if already connected to avoid errors
        let existingConnections = engine.connections(from: engine.mainMixerNode, to: outputNode)
        if !existingConnections.isEmpty {
            engine.disconnectNodeOutput(engine.mainMixerNode)
        }
        engine.connect(engine.mainMixerNode, to: outputNode, format: format)

        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    /// Enable or disable sound effects
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    /// Play a sound effect
    /// - Parameters:
    ///   - type: The type of sound to play
    ///   - throttle: Whether to throttle rapid sounds of the same type
    func play(_ type: SoundType, throttle: Bool = true) {
        guard isEnabled else { return }
        
        // Throttle rapid sounds
        if throttle {
            let now = Date()
            if let lastTime = lastSoundTime[type.rawValue],
               now.timeIntervalSince(lastTime) < throttleInterval {
                return
            }
            lastSoundTime[type.rawValue] = now
        }
        
        var engine: AVAudioEngine
        if let existing = audioEngine {
            engine = existing
        } else {
            setupAudioEngine()
            guard let newEngine = audioEngine else { return }
            engine = newEngine
        }
        
        // Ensure engine is running
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        // Ensure main mixer is connected to output with a valid format
        let outputNode = engine.outputNode
        let outFormat = outputNode.inputFormat(forBus: 0)
        if outFormat.channelCount == 0 || outFormat.sampleRate == 0 {
            if let fallback = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) {
                let existingConnections = engine.connections(from: engine.mainMixerNode, to: outputNode)
                if !existingConnections.isEmpty {
                    engine.disconnectNodeOutput(engine.mainMixerNode)
                }
                engine.connect(engine.mainMixerNode, to: outputNode, format: fallback)
            }
        }
        
        // Create and play the sound
        playSound(type: type, engine: engine)
    }
    
    /// Play a specific sound type
    private func playSound(type: SoundType, engine: AVAudioEngine) {
        // Ensure engine has a valid output format before attaching nodes
        let outputNode = engine.outputNode
        let outputFormat = outputNode.inputFormat(forBus: 0)
        if outputFormat.channelCount == 0 || outputFormat.sampleRate == 0 {
            // Attempt to reconnect main mixer to output with a standard format
            let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            if let fallbackFormat {
                let existingConnections = engine.connections(from: engine.mainMixerNode, to: outputNode)
                if !existingConnections.isEmpty {
                    engine.disconnectNodeOutput(engine.mainMixerNode)
                }
                engine.connect(engine.mainMixerNode, to: outputNode, format: fallbackFormat)
            }
        }
        
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        guard let audioFormat = format else {
            engine.detach(playerNode)
            return
        }
        
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)
        
        // Generate audio buffer based on sound type
        let buffer = generateBuffer(for: type, format: audioFormat)
        
        playerNode.scheduleBuffer(buffer, at: nil, options: []) {
            // Clean up after playback
            DispatchQueue.main.async {
                playerNode.stop()
                // Check if node is still connected before disconnecting
                let connections = engine.connections(from: playerNode, to: engine.mainMixerNode)
                if !connections.isEmpty {
                    engine.disconnectNodeOutput(playerNode)
                }
                // Check if node is still attached before detaching
                if engine.attachedNodes.contains(playerNode) {
                    engine.detach(playerNode)
                }
            }
        }
        
        playerNode.play()
    }
    
    /// Generate audio buffer for a sound type
    private func generateBuffer(for type: SoundType, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let duration: Float = type.duration
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(Int(sampleRate * duration))
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            // Fallback to minimal buffer
            if let fallbackBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100) {
                fallbackBuffer.frameLength = 100
                return fallbackBuffer
            }
            // Last resort: create a minimal buffer with a safe format
            // This should never fail, but if it does, we'll create a basic format
            let safeFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) ?? format
            guard let minimal = AVAudioPCMBuffer(pcmFormat: safeFormat, frameCapacity: 16) else {
                // Ultimate fallback: return a zero-filled buffer using the original format
                // This should never happen, but provides a safe fallback
                if let ultimateBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1) {
                    ultimateBuffer.frameLength = 1
                    if let ch = ultimateBuffer.floatChannelData {
                        ch[0][0] = 0
                    }
                    return ultimateBuffer
                }
                // If even that fails, try one more time with a different format
                // Return a silent buffer to avoid crashing
                if let lastResort = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1),
                   let buffer = AVAudioPCMBuffer(pcmFormat: lastResort, frameCapacity: 1) {
                    buffer.frameLength = 1
                    if let ch = buffer.floatChannelData {
                        ch[0][0] = 0
                    }
                    return buffer
                }
                // Final fallback: return format's buffer (this should always succeed)
                return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1) ?? {
                    // This should never execute, but provides a non-nil return
                    let finalFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) ?? format
                    return AVAudioPCMBuffer(pcmFormat: finalFormat, frameCapacity: 1)!
                }()
            }
            minimal.frameLength = 16
            if let ch = minimal.floatChannelData {
                for i in 0..<Int(minimal.frameLength) { ch[0][i] = 0 }
            }
            return minimal
        }
        
        buffer.frameLength = frameCount
        
        if let ch = buffer.floatChannelData {
            for i in 0..<Int(frameCount) { ch[0][i] = 0 }
        }
        
        guard let channelData = buffer.floatChannelData else { return buffer }
        
        let frequency = type.frequency
        let amplitude: Float = 0.3 * type.volume
        
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / sampleRate
            let sample = generateSample(for: type, time: time, frequency: frequency, amplitude: amplitude)
            channelData[0][frame] = sample
        }
        
        return buffer
    }
    
    /// Generate a single audio sample
    private func generateSample(for type: SoundType, time: Float, frequency: Float, amplitude: Float) -> Float {
        switch type {
        case .click:
            // Short click sound
            let phase = 2.0 * Float.pi * frequency * time
            let s = amplitude * sin(phase) * exp(-time * 10)
            return max(-1, min(1, s))
            
        case .draw:
            // Continuous drawing sound with noise
            let phase = 2.0 * Float.pi * frequency * time
            let noise = (Float.random(in: -0.1...0.1))
            let s = amplitude * (sin(phase) + noise) * exp(-time * 2)
            return max(-1, min(1, s))
            
        case .spray:
            // Spray sound with rapid variations
            let phase = 2.0 * Float.pi * frequency * time
            let noise = Float.random(in: -0.2...0.2)
            let s = amplitude * (sin(phase * 1.5) + noise) * exp(-time * 5)
            return max(-1, min(1, s))
            
        case .eraser:
            // Lower frequency eraser sound
            let phase = 2.0 * Float.pi * frequency * time
            let s = amplitude * sin(phase) * exp(-time * 3)
            return max(-1, min(1, s))
            
        case .stamp:
            // Pop sound for stamps
            let phase = 2.0 * Float.pi * frequency * time
            let s = amplitude * sin(phase) * (1.0 - time * 2) * exp(-time * 8)
            return max(-1, min(1, s))
            
        case .fill:
            // Ascending sweep for fill
            let sweepFreq = frequency + (frequency * 2 - frequency) * time
            let phase = 2.0 * Float.pi * sweepFreq * time
            let s = amplitude * sin(phase) * exp(-time * 3)
            return max(-1, min(1, s))
            
        case .shape:
            // Shape completion sound
            let phase = 2.0 * Float.pi * frequency * time
            let s = amplitude * sin(phase) * exp(-time * 6)
            return max(-1, min(1, s))
            
        case .save:
            // Pleasant tone for save
            let phase = 2.0 * Float.pi * frequency * time
            let s = amplitude * sin(phase) * exp(-time * 2)
            return max(-1, min(1, s))
            
        case .clear:
            // Descending sweep for clear
            let sweepFreq = frequency - (frequency * 0.5) * time
            let phase = 2.0 * Float.pi * sweepFreq * time
            let s = amplitude * sin(phase) * exp(-time * 4)
            return max(-1, min(1, s))
            
        case .success:
            // Success chord (two frequencies)
            let phase1 = 2.0 * Float.pi * frequency * time
            let phase2 = 2.0 * Float.pi * frequency * 1.25 * time
            let s = amplitude * (sin(phase1) + sin(phase2) * 0.5) * exp(-time * 3)
            return max(-1, min(1, s))
            
        case .error:
            // Error sound (lower frequency)
            let phase = 2.0 * Float.pi * frequency * 0.7 * time
            let s = amplitude * sin(phase) * exp(-time * 5)
            return max(-1, min(1, s))
        }
    }
}

// MARK: - SoundType

/// Types of sound effects available
enum SoundType: String {
    case click      // Button clicks, tool selection
    case draw       // Drawing with pencil
    case spray      // Spray tool
    case eraser     // Eraser tool
    case stamp      // Emoji/text stamp
    case fill       // Fill tool
    case shape      // Shape completion
    case save       // Save operation
    case clear      // Clear operation
    case success    // Success notification
    case error      // Error notification
    
    /// Frequency in Hz
    var frequency: Float {
        switch self {
        case .click: return 800
        case .draw: return 200 + Float.random(in: 0...100)
        case .spray: return 300 + Float.random(in: 0...200)
        case .eraser: return 150 + Float.random(in: 0...50)
        case .stamp: return 600
        case .fill: return 400
        case .shape: return 500
        case .save: return 523.25 // C5 note
        case .clear: return 800
        case .success: return 523.25 // C5
        case .error: return 200
        }
    }
    
    /// Duration in seconds
    var duration: Float {
        switch self {
        case .click: return 0.05
        case .draw: return 0.1
        case .spray: return 0.05
        case .eraser: return 0.1
        case .stamp: return 0.15
        case .fill: return 0.3
        case .shape: return 0.2
        case .save: return 0.3
        case .clear: return 0.5
        case .success: return 0.3
        case .error: return 0.2
        }
    }
    
    /// Volume multiplier (0.0 to 1.0)
    var volume: Float {
        switch self {
        case .click: return 0.5
        case .draw: return 0.3
        case .spray: return 0.2
        case .eraser: return 0.3
        case .stamp: return 0.6
        case .fill: return 0.5
        case .shape: return 0.5
        case .save: return 0.4
        case .clear: return 0.4
        case .success: return 0.5
        case .error: return 0.4
        }
    }
}

// MARK: - Sound Helper Extension

extension AppPreferences {
    /// Play a sound effect if enabled
    func playSound(_ type: SoundType) {
        if enableSoundEffects {
            SoundEffects.shared.setEnabled(true)
            SoundEffects.shared.play(type)
        } else {
            SoundEffects.shared.setEnabled(false)
        }
    }
}

