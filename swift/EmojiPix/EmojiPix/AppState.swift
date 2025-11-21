//
//  AppState.swift
//  EmojiPix
//
//  Global application state management.
//

import SwiftUI
import Combine

/// Global application state
class AppState: ObservableObject {
    @Published var showStartScreen: Bool = true
    @Published var imageToLoad: CGImage?
    
    init() {
        // Show start screen on first launch
        // Could check UserDefaults here to remember user preference
    }
}

