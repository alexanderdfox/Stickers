//
//  AppPreferences.swift
//  EmojiPix
//
//  Apple HIG-compliant preferences and settings

import SwiftUI
import Combine

// App-wide preferences following Apple HIG
class AppPreferences: ObservableObject {
    static let shared = AppPreferences()
    
    @Published var enableHaptics: Bool = true
    @Published var enableSoundEffects: Bool = true
    @Published var showGrid: Bool = false
    @Published var autoSave: Bool = true
    
    private init() {}
}

// Haptic feedback helper
struct HapticFeedback {
    #if os(iOS)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    #else
    // macOS doesn't have haptic feedback
    static func light() {}
    static func medium() {}
    static func heavy() {}
    static func selection() {}
    static func notification(_ type: Any) {}
    #endif
}

