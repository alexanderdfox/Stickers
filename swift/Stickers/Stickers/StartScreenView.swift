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
    @State private var showError = false
    @State private var errorMessage = ""
    
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
            allowedContentTypes: [.png, .jpeg, .image, .heic, .heif, .tiff, .bmp, .gif],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Error Loading Image", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        #elseif os(iOS)
        .sheet(isPresented: $showFilePicker) {
            DocumentPickerView(showStartScreen: $showStartScreen, appState: appState, onError: { message in
                errorMessage = message
                showError = true
            })
        }
        .alert("Error Loading Image", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        #endif
    }
    
    #if os(macOS)
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showErrorMessage("No file selected")
                return
            }
            // Load the image file on main thread
            DispatchQueue.main.async {
                loadImage(from: url)
            }
        case .failure(let error):
            showErrorMessage("Failed to select file: \(error.localizedDescription)")
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func loadImage(from url: URL) {
        // Access security-scoped resource for fileImporter URLs
        guard url.startAccessingSecurityScopedResource() else {
            showErrorMessage("Failed to access the selected file. Please try again.")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Load image from file URL using CGImageSource for better format support
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            showErrorMessage("Unable to read image file. The file may be corrupted or in an unsupported format.")
            return
        }
        
        // Check image count
        let imageCount = CGImageSourceGetCount(imageSource)
        guard imageCount > 0 else {
            showErrorMessage("The selected file does not contain any images.")
            return
        }
        
        // Get image properties to check size
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
            showErrorMessage("Unable to read image properties.")
            return
        }
        
        // Validate image size to prevent memory issues (max 10,000 x 10,000 pixels)
        let maxDimension = 10000
        if width > maxDimension || height > maxDimension {
            showErrorMessage("Image is too large (max \(maxDimension)x\(maxDimension) pixels). Current size: \(width)x\(height)")
            return
        }
        
        // Validate minimum size
        if width < 1 || height < 1 {
            showErrorMessage("Image dimensions are invalid.")
            return
        }
        
        // Create the CGImage
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            showErrorMessage("Failed to decode image. The file may be corrupted.")
            return
        }
        
        // Set the image to load in app state (on main thread)
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
    let onError: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .png, .jpeg, .heic, .heif, .tiff, .bmp, .gif])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(showStartScreen: $showStartScreen, appState: appState, dismiss: dismiss, onError: onError)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var showStartScreen: Bool
        @ObservedObject var appState: AppState
        let dismiss: DismissAction
        let onError: (String) -> Void
        
        init(showStartScreen: Binding<Bool>, appState: AppState, dismiss: DismissAction, onError: @escaping (String) -> Void) {
            self._showStartScreen = showStartScreen
            self.appState = appState
            self.dismiss = dismiss
            self.onError = onError
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                dismiss()
                return
            }
            
            // Load image on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.loadImage(from: url)
            }
        }
        
        private func loadImage(from url: URL) {
            // Access security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                onError("Failed to access the selected file. Please try again.")
                dismiss()
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // Load image from file URL using CGImageSource for better format support
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                onError("Unable to read image file. The file may be corrupted or in an unsupported format.")
                dismiss()
                return
            }
            
            // Check image count
            let imageCount = CGImageSourceGetCount(imageSource)
            guard imageCount > 0 else {
                onError("The selected file does not contain any images.")
                dismiss()
                return
            }
            
            // Get image properties to check size
            guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
                  let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
                onError("Unable to read image properties.")
                dismiss()
                return
            }
            
            // Validate image size to prevent memory issues (max 10,000 x 10,000 pixels)
            let maxDimension = 10000
            if width > maxDimension || height > maxDimension {
                onError("Image is too large (max \(maxDimension)x\(maxDimension) pixels). Current size: \(width)x\(height)")
                dismiss()
                return
            }
            
            // Validate minimum size
            if width < 1 || height < 1 {
                onError("Image dimensions are invalid.")
                dismiss()
                return
            }
            
            // Create the CGImage
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                onError("Failed to decode image. The file may be corrupted.")
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

