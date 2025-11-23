//
//  StickersApp.swift
//  Stickers
//
//  Main application entry point and app lifecycle management.
//  Handles window management, menu commands, and settings on macOS.
//

import SwiftUI

/// Main application structure for Stickers drawing application
@main
struct StickersApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.showStartScreen {
                StartScreenView(showStartScreen: $appState.showStartScreen)
                    .environmentObject(appState)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: appState.showStartScreen)
            } else {
                ContentView()
                    .environmentObject(appState)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: appState.showStartScreen)
            }
        }
        #if os(macOS)
        .commands {
            // Remove default "New" menu item since we don't use document model
            CommandGroup(replacing: .newItem) {}
            
            // Add custom toolbar command for sidebar toggle
            CommandGroup(after: .toolbar) {
                Button("Toggle Sidebar") {
                    // Sidebar toggle is handled in ContentView
                }
                .keyboardShortcut("b", modifiers: [.command])
            }
        }
        #endif
        
        #if os(macOS)
        // macOS Settings window
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if os(macOS)
/// Settings view for macOS preferences
struct SettingsView: View {
    @StateObject private var preferences = AppPreferences.shared
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 500, height: 300)
    }
}

/// General preferences settings view
struct GeneralSettingsView: View {
    @StateObject private var preferences = AppPreferences.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Haptic Feedback", isOn: $preferences.enableHaptics)
                Toggle("Enable Sound Effects", isOn: $preferences.enableSoundEffects)
                    .onChange(of: preferences.enableSoundEffects) { oldValue, newValue in
                        SoundEffects.shared.setEnabled(newValue)
                    }
                Toggle("Show Grid", isOn: $preferences.showGrid)
                Toggle("Auto-Save", isOn: $preferences.autoSave)
            } header: {
                Text("Preferences")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            SoundEffects.shared.setEnabled(preferences.enableSoundEffects)
        }
    }
}
#endif
