//
//  StartScreenView.swift
//  Stickers
//
//  Start screen with New and Open options for the application.
//

import SwiftUI
import UniformTypeIdentifiers
import ImageIO

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - StartScreenView

/// Start screen view with New and Open options
struct StartScreenView: View {
    @Binding var showStartScreen: Bool
    @EnvironmentObject var appState: AppState
    @State private var showFilePicker = false
    
    var body: some View {
        ZStack {
            // Vibrant multi-color gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.85, blue: 0.95),  // Soft pink
                    Color(red: 0.85, green: 0.90, blue: 1.0),   // Light blue
                    Color(red: 0.90, green: 0.95, blue: 0.85),   // Mint green
                    Color(red: 1.0, green: 0.95, blue: 0.85)     // Peach
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated gradient overlay for depth
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.70, blue: 0.90).opacity(0.3),  // Vibrant pink
                    Color(red: 0.70, green: 0.85, blue: 1.0).opacity(0.3),   // Sky blue
                    Color(red: 0.80, green: 1.0, blue: 0.80).opacity(0.3),  // Bright green
                    Color(red: 1.0, green: 0.90, blue: 0.70).opacity(0.3)   // Warm yellow
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                // App Icon/Title with gradient text
                VStack(spacing: 24) {
                    // Large emoji with shadow
                    Text("🎨")
                        .font(.system(size: 100))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    // Gradient text for title
                    Text("Stickers")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.3, blue: 0.6),   // Deep pink
                                    Color(red: 0.4, green: 0.5, blue: 0.9),   // Royal blue
                                    Color(red: 0.3, green: 0.7, blue: 0.5),   // Emerald
                                    Color(red: 0.9, green: 0.6, blue: 0.2)    // Orange
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    Text("Draw, Stamp, and Create with Emojis!")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.5, blue: 0.7),
                                    Color(red: 0.7, green: 0.5, blue: 0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .padding(.top, 80)
                
                Spacer()
                
                // Action Buttons with vibrant colors
                VStack(spacing: 24) {
                    // New Drawing Button - Vibrant gradient
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStartScreen = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                            Text("New Drawing")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: 300)
                        .frame(height: 68)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.4, blue: 0.6),   // Vibrant pink
                                    Color(red: 0.6, green: 0.4, blue: 0.9),    // Purple
                                    Color(red: 0.4, green: 0.6, blue: 0.9)     // Blue
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.5), radius: 15, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Open Drawing Button - Elegant outline with gradient
                    Button(action: {
                        showFilePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 28, weight: .semibold))
                            Text("Open Drawing")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: 300)
                        .frame(height: 68)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.5, blue: 0.8),   // Deep blue
                                    Color(red: 0.5, green: 0.3, blue: 0.7)    // Deep purple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.6, blue: 0.9),
                                            Color(red: 0.6, green: 0.4, blue: 0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.bottom, 100)
            }
            .padding()
        }
        #if os(macOS)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.png, .jpeg, .image],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        #elseif os(iOS)
        .sheet(isPresented: $showFilePicker) {
            DocumentPickerView(showStartScreen: $showStartScreen, appState: appState)
        }
        #endif
    }
    
    #if os(macOS)
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Load the image file
            loadImage(from: url)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
    
    private func loadImage(from url: URL) {
        // Access security-scoped resource for fileImporter URLs
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource: \(url)")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Load image from file URL
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to load image from URL: \(url)")
            return
        }
        
        // Set the image to load in app state
        appState.imageToLoad = cgImage
        
        // Close the start screen
        withAnimation(.easeInOut(duration: 0.3)) {
            showStartScreen = false
        }
    }
    #endif
}

#if os(iOS)
// MARK: - DocumentPickerView

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var showStartScreen: Bool
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .png, .jpeg])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(showStartScreen: $showStartScreen, appState: appState, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var showStartScreen: Bool
        @ObservedObject var appState: AppState
        let dismiss: DismissAction
        
        init(showStartScreen: Binding<Bool>, appState: AppState, dismiss: DismissAction) {
            self._showStartScreen = showStartScreen
            self.appState = appState
            self.dismiss = dismiss
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                dismiss()
                return
            }
            
            // Load image from file URL
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource")
                dismiss()
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                print("Failed to load image from URL: \(url)")
                dismiss()
                return
            }
            
            // Set the image to load in app state
            appState.imageToLoad = cgImage
            
            dismiss()
            withAnimation(.easeInOut(duration: 0.3)) {
                showStartScreen = false
            }
        }
    }
}
#endif

// MARK: - ScaleButtonStyle

/// Button style that provides scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

