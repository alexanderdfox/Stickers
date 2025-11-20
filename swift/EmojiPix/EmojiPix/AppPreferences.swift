//
//  AppPreferences.swift
//  EmojiPix
//
//  Manages application-wide preferences and settings following Apple HIG.
//  Provides haptic feedback functionality for iOS devices.
//

import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

// MARK: - AppPreferences

/// App-wide preferences manager following Apple Human Interface Guidelines
/// Singleton pattern ensures consistent preferences across the application
class AppPreferences: ObservableObject {
    /// Shared singleton instance
    static let shared = AppPreferences()
    
    /// Enable haptic feedback for user interactions
    @Published var enableHaptics: Bool = true
    
    /// Enable sound effects for actions
    @Published var enableSoundEffects: Bool = true
    
    /// Show grid overlay on canvas
    @Published var showGrid: Bool = false
    
    /// Automatically save canvas periodically
    @Published var autoSave: Bool = true
    
    /// Private initializer to enforce singleton pattern
    private init() {}
}

// MARK: - HapticFeedback

/// Haptic feedback helper for iOS devices
/// Provides various types of haptic feedback for enhanced user experience
struct HapticFeedback {
    #if os(iOS)
    /// Light impact haptic feedback
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact haptic feedback
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact haptic feedback
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Selection change haptic feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Notification haptic feedback
    /// - Parameter type: The type of notification feedback
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// Success haptic feedback (notification type: .success)
    static func success() {
        notification(.success)
    }
    
    /// Error haptic feedback (notification type: .error)
    static func error() {
        notification(.error)
    }
    
    /// Warning haptic feedback (notification type: .warning)
    static func warning() {
        notification(.warning)
    }
    #else
    // macOS doesn't have haptic feedback, so these are no-ops
    static func light() {}
    static func medium() {}
    static func heavy() {}
    static func selection() {}
    static func notification(_ type: Any) {}
    static func success() {}
    static func error() {}
    static func warning() {}
    #endif
}
