//
//  SoundEffects.swift
//  EmojiPix
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
    private var isEnabled: Bool = true
    private var lastSoundTime: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 0.05 // Minimum time between same sound type
    
    private init() {
        setupAudioEngine()
    }
    
    /// Setup the audio engine
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else { return }
        
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
        
        guard let engine = audioEngine else {
            setupAudioEngine()
            return
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
        
        // Create and play the sound
        playSound(type: type, engine: engine)
    }
    
    /// Play a specific sound type
    private func playSound(type: SoundType, engine: AVAudioEngine) {
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        guard let audioFormat = format else { return }
        
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)
        
        // Generate audio buffer based on sound type
        let buffer = generateBuffer(for: type, format: audioFormat)
        
        playerNode.scheduleBuffer(buffer) {
            // Clean up after playback
            DispatchQueue.main.async {
                engine.detach(playerNode)
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
            return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100)!
        }
        
        buffer.frameLength = frameCount
        
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
            return amplitude * sin(phase) * exp(-time * 10)
            
        case .draw:
            // Continuous drawing sound with noise
            let phase = 2.0 * Float.pi * frequency * time
            let noise = (Float.random(in: -0.1...0.1))
            return amplitude * (sin(phase) + noise) * exp(-time * 2)
            
        case .spray:
            // Spray sound with rapid variations
            let phase = 2.0 * Float.pi * frequency * time
            let noise = Float.random(in: -0.2...0.2)
            return amplitude * (sin(phase * 1.5) + noise) * exp(-time * 5)
            
        case .eraser:
            // Lower frequency eraser sound
            let phase = 2.0 * Float.pi * frequency * time
            return amplitude * sin(phase) * exp(-time * 3)
            
        case .stamp:
            // Pop sound for stamps
            let phase = 2.0 * Float.pi * frequency * time
            return amplitude * sin(phase) * (1.0 - time * 2) * exp(-time * 8)
            
        case .fill:
            // Ascending sweep for fill
            let sweepFreq = frequency + (frequency * 2 - frequency) * time
            let phase = 2.0 * Float.pi * sweepFreq * time
            return amplitude * sin(phase) * exp(-time * 3)
            
        case .shape:
            // Shape completion sound
            let phase = 2.0 * Float.pi * frequency * time
            return amplitude * sin(phase) * exp(-time * 6)
            
        case .save:
            // Pleasant tone for save
            let phase = 2.0 * Float.pi * frequency * time
            return amplitude * sin(phase) * exp(-time * 2)
            
        case .clear:
            // Descending sweep for clear
            let sweepFreq = frequency - (frequency * 0.5) * time
            let phase = 2.0 * Float.pi * sweepFreq * time
            return amplitude * sin(phase) * exp(-time * 4)
            
        case .success:
            // Success chord (two frequencies)
            let phase1 = 2.0 * Float.pi * frequency * time
            let phase2 = 2.0 * Float.pi * frequency * 1.25 * time
            return amplitude * (sin(phase1) + sin(phase2) * 0.5) * exp(-time * 3)
            
        case .error:
            // Error sound (lower frequency)
            let phase = 2.0 * Float.pi * frequency * 0.7 * time
            return amplitude * sin(phase) * exp(-time * 5)
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

