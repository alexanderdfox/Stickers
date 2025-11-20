//
//  EmojiPixApp.swift
//  EmojiPix
//
//  Created by Alexander Fox on 11/20/25.
//

import SwiftUI

@main
struct EmojiPixApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .toolbar) {
                Button("Toggle Sidebar") {
                    // Handle sidebar toggle
                }
                .keyboardShortcut("b", modifiers: [.command])
            }
        }
        #endif
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if os(macOS)
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

struct GeneralSettingsView: View {
    @StateObject private var preferences = AppPreferences.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Haptic Feedback", isOn: $preferences.enableHaptics)
                Toggle("Enable Sound Effects", isOn: $preferences.enableSoundEffects)
                Toggle("Show Grid", isOn: $preferences.showGrid)
                Toggle("Auto-Save", isOn: $preferences.autoSave)
            } header: {
                Text("Preferences")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
#endif
