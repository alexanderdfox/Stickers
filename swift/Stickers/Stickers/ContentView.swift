//
//  ContentView.swift
//  Stickers
//
//  Main content view that orchestrates the application layout.
//  Handles platform-specific UI (macOS/iOS), save functionality, canvas management,
//  and window layout. Manages save panels and image export (PNG).
//

import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
import ImageIO
#elseif canImport(UIKit)
import UIKit
import Photos
import PhotosUI
#endif

// MARK: - ContentView

/// Main application view
/// Coordinates header, toolbar, canvas, and bottom toolbar across platforms
struct ContentView: View {
    @StateObject private var state = DrawingState()
    @EnvironmentObject var appState: AppState
    @State private var showSidebar = true
    @State private var showEmojiPicker = false
    @State private var showHelp = false
    #if os(iOS)
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showExportOptions = false
    @State private var exportFormat: ExportFormat = .png
    @State private var exportSize: ExportSize = .oneX
    @State private var importedImage: UIImage?
    @State private var importedImagePosition: CGPoint = .zero
    @State private var isDraggingImage: Bool = false
    @State private var dragOffset: CGPoint = .zero
    
    // Keep a strong reference during save to ensure the helper lives until callback fires
    private static var imageSaveHelper: IOSImageSaveHelper?
    #elseif os(macOS)
    @State private var showImagePicker = false
    @State private var importedImage: NSImage?
    @State private var importedImagePosition: CGPoint = .zero
    @State private var isDraggingImage: Bool = false
    @State private var dragOffset: CGPoint = .zero
    @State private var exportDocument: AnyFileDocument?
    @State private var showFileExporter = false
    @State private var showExportOptions = false
    @State private var exportFormat: ExportFormat = .png
    @State private var exportSize: ExportSize = .oneX
    #endif
    
    private var headerTitleSize: CGFloat {
        #if os(macOS)
        return 24
        #else
        return 22
        #endif
    }
    
    private var helpButtonSize: CGFloat {
        #if os(macOS)
        return 13
        #else
        return 15
        #endif
    }
    
    private var headerPaddingH: CGFloat {
        #if os(macOS)
        return 16
        #else
        return 12
        #endif
    }
    
    private var headerPaddingV: CGFloat {
        #if os(macOS)
        return 12
        #else
        return 10
        #endif
    }
    
    private var headerBackground: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }
    
    private var toolbarSpacing: CGFloat {
        #if os(macOS)
        return 8
        #else
        return 12
        #endif
    }
    
    private var toolbarButtonSize: CGFloat {
        #if os(macOS)
        return 14
        #else
        return 16
        #endif
    }
    
    private var toolbarButtonFrame: CGFloat {
        #if os(macOS)
        return 28
        #else
        return 44
        #endif
    }
    
    private var dividerHeight: CGFloat {
        #if os(macOS)
        return 20
        #else
        return 30
        #endif
    }
    
    private var zoomButtonSize: CGFloat {
        #if os(macOS)
        return 12
        #else
        return 14
        #endif
    }
    
    private var zoomButtonFrame: CGFloat {
        #if os(macOS)
        return 24
        #else
        return 36
        #endif
    }
    
    private var zoomTextSize: CGFloat {
        #if os(macOS)
        return 11
        #else
        return 13
        #endif
    }
    
    private var zoomTextWidth: CGFloat {
        #if os(macOS)
        return 50
        #else
        return 60
        #endif
    }
    
    private var zoomPaddingH: CGFloat {
        #if os(macOS)
        return 8
        #else
        return 12
        #endif
    }
    
    private var zoomPaddingV: CGFloat {
        #if os(macOS)
        return 4
        #else
        return 6
        #endif
    }
    
    private var zoomBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }
    
    private var toolbarPaddingH: CGFloat {
        #if os(macOS)
        return 16
        #else
        return 12
        #endif
    }
    
    private var toolbarPaddingV: CGFloat {
        #if os(macOS)
        return 10
        #else
        return 12
        #endif
    }
    
    private var toolbarBackground: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }
    
    var body: some View {
        Group {
            #if os(macOS)
            macOSLayout
            #else
            iOSLayout
            #endif
        }
        .onChange(of: appState.imageToLoad) { oldValue, newValue in
            if let image = newValue {
                state.loadImageAsBackground(image)
                // Clear the image after loading
                appState.imageToLoad = nil
            }
        }
    }
    
    #if os(macOS)
    private var macOSLayout: some View {
        HSplitView {
            if showSidebar {
                ToolbarView(state: state)
                    .frame(minWidth: 280, idealWidth: 280, maxWidth: 300)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Canvas
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    CanvasView(
                        state: state,
                        importedImage: $importedImage,
                        importedImagePosition: $importedImagePosition,
                        isDraggingImage: $isDraggingImage,
                        onPlaceImage: placeImportedImage
                    )
                    .padding(20)
                }
                .background(Color(nsColor: .textBackgroundColor))
                
                Divider()
                
                // Bottom toolbar
                bottomToolbar
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $state.selectedEmoji)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(exportFormat: $exportFormat, exportSize: $exportSize) {
                self.performExport()
            }
        }
        #if os(macOS)
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    loadImageFromURL(url)
                }
            case .failure(let error):
                print("File import error: \(error.localizedDescription)")
            }
        }
        #endif
        .fileExporter(
            isPresented: $showFileExporter,
            document: exportDocument,
            contentType: exportFormat.contentType,
            defaultFilename: defaultFileName()
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    // Convert to requested format if needed
                    if self.exportFormat != .png {
                        self.convertExportFormat(at: url)
                    } else {
                        self.showSaveSuccess(at: url)
                    }
                case .failure(let error):
                    self.showSaveError(error.localizedDescription)
                }
                // Clear document after export
                self.exportDocument = nil
                self.showFileExporter = false
            }
        }
    }
    #else
    private var iOSLayout: some View {
        NavigationSplitView {
            if showSidebar {
                ToolbarView(state: state)
                    .navigationBarTitleDisplayMode(.inline)
            }
        } detail: {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Canvas
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    CanvasView(
                        state: state,
                        importedImage: $importedImage,
                        importedImagePosition: $importedImagePosition,
                        isDraggingImage: $isDraggingImage,
                        onPlaceImage: placeImportedImage
                    )
                    .padding(16)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                
                Divider()
                
                // Bottom toolbar
                bottomToolbar
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $state.selectedEmoji)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        #if os(iOS)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                self.handleImportedImage(image)
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(exportFormat: $exportFormat, exportSize: $exportSize) {
                self.performSave()
            }
        }
        #endif
    }
    #endif
    
    private var headerView: some View {
        HStack(spacing: 12) {
            #if os(macOS)
            Button(action: { 
                HapticFeedback.selection()
                withAnimation(.easeInOut(duration: 0.2)) { 
                    showSidebar.toggle() 
                }
            }) {
                Image(systemName: showSidebar ? "sidebar.left" : "sidebar.right")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help("Toggle Sidebar")
            .keyboardShortcut("b", modifiers: .command)
            #else
            Button(action: { 
                HapticFeedback.selection()
                withAnimation(.easeInOut(duration: 0.2)) { 
                    showSidebar.toggle() 
                }
            }) {
                Image(systemName: showSidebar ? "sidebar.left" : "sidebar.right")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #endif
            
            Text("🎨 Stickers")
                .font(.system(size: headerTitleSize, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { 
                HapticFeedback.selection()
                showHelp = true 
            }) {
                Label("Help", systemImage: "questionmark.circle")
                    .font(.system(size: helpButtonSize, weight: .medium))
                    .foregroundColor(.secondary)
            }
            #if os(macOS)
            .buttonStyle(.borderless)
            .help("Show Help (⌘?)")
            .keyboardShortcut("?", modifiers: [])
            #else
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            #endif
        }
        .padding(.horizontal, headerPaddingH)
        .padding(.vertical, headerPaddingV)
        .background(headerBackground)
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: toolbarSpacing) {
            // Undo/Redo
            Button(action: { 
                HapticFeedback.selection()
                AppPreferences.shared.playSound(.click)
                _ = state.undo() 
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: toolbarButtonSize, weight: .medium))
                    .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                    .contentShape(Rectangle())
            }
            .disabled(!state.canUndo())
            #if os(macOS)
            .buttonStyle(.borderless)
            .help("Undo (⌘Z)")
            .keyboardShortcut("z", modifiers: .command)
            #else
            .buttonStyle(.plain)
            #endif
            
            Button(action: { 
                HapticFeedback.selection()
                AppPreferences.shared.playSound(.click)
                _ = state.redo() 
            }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: toolbarButtonSize, weight: .medium))
                    .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                    .contentShape(Rectangle())
            }
            .disabled(!state.canRedo())
            #if os(macOS)
            .buttonStyle(.borderless)
            .help("Redo (⌘⇧Z)")
            .keyboardShortcut("z", modifiers: [.command, .shift])
            #else
            .buttonStyle(.plain)
            #endif
            
            Divider()
                .frame(height: dividerHeight)
            
            // Cut/Copy/Paste (only show when selection exists)
            if state.hasSelection {
                Button(action: {
                    HapticFeedback.selection()
                    AppPreferences.shared.playSound(.click)
                    state.cutSelection()
                }) {
                    Image(systemName: "scissors")
                        .font(.system(size: toolbarButtonSize, weight: .medium))
                        .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                        .contentShape(Rectangle())
                }
                #if os(macOS)
                .buttonStyle(.borderless)
                .help("Cut Selection (⌘X)")
                .keyboardShortcut("x", modifiers: .command)
                #else
                .buttonStyle(.plain)
                #endif
                
                Button(action: {
                    HapticFeedback.selection()
                    AppPreferences.shared.playSound(.click)
                    state.copySelection()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: toolbarButtonSize, weight: .medium))
                        .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                        .contentShape(Rectangle())
                }
                #if os(macOS)
                .buttonStyle(.borderless)
                .help("Copy Selection (⌘C)")
                .keyboardShortcut("c", modifiers: .command)
                #else
                .buttonStyle(.plain)
                #endif
            }
            
            if state.clipboard != nil {
                Button(action: {
                    HapticFeedback.selection()
                    AppPreferences.shared.playSound(.click)
                    // Paste at center of canvas
                    let pastePoint = CGPoint(
                        x: state.canvasWidth / 2,
                        y: state.canvasHeight / 2
                    )
                    state.pasteSelection(at: pastePoint)
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: toolbarButtonSize, weight: .medium))
                        .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                        .contentShape(Rectangle())
                }
                #if os(macOS)
                .buttonStyle(.borderless)
                .help("Paste (⌘V)")
                .keyboardShortcut("v", modifiers: .command)
                #else
                .buttonStyle(.plain)
                #endif
            }
            
            Divider()
                .frame(height: dividerHeight)
            
            // Clear
            Button(action: {
                AppPreferences.shared.playSound(.clear)
                clearCanvas()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: toolbarButtonSize, weight: .medium))
                    .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                    .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.borderless)
            .help("Clear Active Layer")
            .keyboardShortcut(.delete, modifiers: [])
            #else
            .buttonStyle(.plain)
            #endif
            
            // Import
            Button(action: {
                HapticFeedback.medium()
                #if os(iOS)
                showImagePickerOptions()
                #elseif os(macOS)
                showImagePicker = true
                #endif
            }) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: toolbarButtonSize, weight: .medium))
                    .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                    .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.borderless)
            .help("Import Image")
            #else
            .buttonStyle(.plain)
            #endif
            
            // Place imported image button (shown when image is being dragged)
            #if os(iOS)
            if importedImage != nil {
                Button(action: {
                    HapticFeedback.medium()
                    placeImportedImage()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: toolbarButtonSize, weight: .medium))
                        .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                        .contentShape(Rectangle())
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
            #elseif os(macOS)
            if importedImage != nil {
                Button(action: {
                    placeImportedImage()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: toolbarButtonSize, weight: .medium))
                        .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                        .contentShape(Rectangle())
                        .foregroundColor(.green)
                }
                .buttonStyle(.borderless)
                .help("Place Image")
            }
            #endif
            
            // Save
            Button(action: {
                HapticFeedback.medium()
                AppPreferences.shared.playSound(.save)
                saveImage()
            }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: toolbarButtonSize, weight: .medium))
                    .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                    .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.borderless)
            .help("Save Image (⌘S)")
            .keyboardShortcut("s", modifiers: .command)
            #else
            .buttonStyle(.plain)
            #endif
            
            Divider()
                .frame(height: dividerHeight)
            
            // New/Start Screen
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.showStartScreen = true
                }
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: toolbarButtonSize, weight: .medium))
                    .frame(width: toolbarButtonFrame, height: toolbarButtonFrame)
                    .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.borderless)
            .help("New Drawing (⌘N)")
            .keyboardShortcut("n", modifiers: .command)
            #else
            .buttonStyle(.plain)
            #endif
            
            Spacer()
            
            // Zoom controls
            HStack(spacing: 6) {
                Button(action: { 
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.canvasZoom = max(0.25, state.canvasZoom - 0.25)
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: zoomButtonSize, weight: .medium))
                        .frame(width: zoomButtonFrame, height: zoomButtonFrame)
                        .contentShape(Rectangle())
                }
                #if os(macOS)
                .buttonStyle(.borderless)
                .help("Zoom Out (-)")
                .keyboardShortcut("-", modifiers: [])
                #else
                .buttonStyle(.plain)
                #endif
                
                Text("\(Int(state.canvasZoom * 100))%")
                    .font(.system(size: zoomTextSize, weight: .semibold, design: .monospaced))
                    .frame(width: zoomTextWidth, alignment: .center)
                    .foregroundColor(.secondary)
                
                Button(action: { 
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.canvasZoom = min(3.0, state.canvasZoom + 0.25)
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: zoomButtonSize, weight: .medium))
                        .frame(width: zoomButtonFrame, height: zoomButtonFrame)
                        .contentShape(Rectangle())
                }
                #if os(macOS)
                .buttonStyle(.borderless)
                .help("Zoom In (+)")
                .keyboardShortcut("=", modifiers: [])
                #else
                .buttonStyle(.plain)
                #endif
            }
            .padding(.horizontal, zoomPaddingH)
            .padding(.vertical, zoomPaddingV)
            .background(zoomBackground)
            .cornerRadius(8)
        }
        .padding(.horizontal, toolbarPaddingH)
        .padding(.vertical, toolbarPaddingV)
        .background(toolbarBackground)
    }
    
    private func clearCanvas() {
        #if os(macOS)
        let alert = NSAlert()
        alert.messageText = "Clear Layer"
        alert.informativeText = "Are you sure you want to clear the active layer? This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            state.activeLayer?.canvas.clear(color: .white)
            state.saveState()
        }
        #else
        // iOS: Use confirmation dialog
        state.activeLayer?.canvas.clear(color: .white)
        state.saveState()
        #endif
    }
    
    private func saveImage() {
        #if os(iOS)
        // iOS: Show export options first
        showExportOptions = true
        #elseif os(macOS)
        // macOS: Show export options first
        showExportOptions = true
        #endif
    }
    
    #if os(iOS)
    private func performSave() {
        DispatchQueue.main.async {
            let baseSize = CGSize(width: self.state.canvasWidth, height: self.state.canvasHeight)
            guard baseSize.width > 0, baseSize.height > 0 else {
                self.showIOSSaveError("Invalid canvas size")
                return
            }
            
            // Apply export size multiplier
            let exportSizeMultiplier = self.exportSize.multiplier
            let exportSize = CGSize(width: baseSize.width * exportSizeMultiplier, height: baseSize.height * exportSizeMultiplier)
            
            let renderer = UIGraphicsImageRenderer(size: exportSize)
            let image = renderer.image { context in
                // Scale context to export size
                context.cgContext.scaleBy(x: exportSizeMultiplier, y: exportSizeMultiplier)
                
                for layer in self.state.layers where layer.isVisible {
                    if let cgImage = layer.canvas.createImage() {
                        context.cgContext.saveGState()
                        context.cgContext.setAlpha(CGFloat(layer.opacity))
                        context.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: baseSize))
                        context.cgContext.restoreGState()
                    }
                }
            }
            
            // Convert to requested format
            let finalImage: UIImage
            switch self.exportFormat {
            case .png:
                finalImage = image
            case .jpeg:
                if let jpegData = image.jpegData(compressionQuality: 0.9),
                   let jpegImage = UIImage(data: jpegData) {
                    finalImage = jpegImage
                } else {
                    finalImage = image
                }
            case .icns:
                // ICNS not supported on iOS, fallback to PNG
                finalImage = image
            }
            
            // Save to photo library
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized || status == .limited {
                    let helper = IOSImageSaveHelper { error in
                        ContentView.imageSaveHelper = nil
                        DispatchQueue.main.async {
                            if let error = error {
                                self.showIOSSaveError("Failed to save: \(error.localizedDescription)")
                            } else {
                                HapticFeedback.success()
                            }
                        }
                    }
                    ContentView.imageSaveHelper = helper
                    UIImageWriteToSavedPhotosAlbum(finalImage, helper, #selector(IOSImageSaveHelper.image(_:didFinishSavingWithError:contextInfo:)), nil)
                } else {
                    DispatchQueue.main.async {
                        self.showIOSSaveError("Photo library access denied. Please enable access in Settings.")
                    }
                }
            }
        }
    }
    #elseif os(macOS)
    private func performSave() {
        // macOS: Use fileExporter
        // Ensure we're on main thread
        if Thread.isMainThread {
            self.performExport()
        } else {
            DispatchQueue.main.async {
                self.performExport()
            }
        }
    }
    #endif
    
    #if os(iOS)
    private func handleImportedImage(_ image: UIImage) {
        // Create a new layer for the imported image
        state.addLayer()
        if let newLayer = state.activeLayer {
            newLayer.name = "Imported Image"
        }
        
        // Store the image and set initial position (centered)
        importedImage = image
        let canvasSize = CGSize(width: state.canvasWidth, height: state.canvasHeight)
        if let cgImage = image.cgImage {
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height)
            let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            importedImagePosition = CGPoint(
                x: (canvasSize.width - scaledSize.width) / 2,
                y: (canvasSize.height - scaledSize.height) / 2
            )
        } else {
            importedImagePosition = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        }
    }
    
    private func placeImportedImage() {
        guard let image = importedImage,
              let cgImage = image.cgImage,
              let activeLayer = state.activeLayer,
              let context = activeLayer.canvas.context else {
            return
        }
        
        // Draw the imported image at the current position
        let canvasSize = CGSize(width: state.canvasWidth, height: state.canvasHeight)
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        context.draw(cgImage, in: CGRect(
            x: importedImagePosition.x,
            y: importedImagePosition.y,
            width: scaledSize.width,
            height: scaledSize.height
        ))
        
        // Clear the temporary image
        importedImage = nil
        state.saveState()
    }
    #elseif os(macOS)
    private func loadImageFromURL(_ url: URL) {
        // Access security-scoped resource for fileImporter URLs
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource: \(url)")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Try loading as NSImage first (simpler for most cases)
        if let nsImage = NSImage(contentsOf: url) {
            handleImportedImage(nsImage)
            return
        }
        
        // Fallback: Load using CGImageSource for better compatibility
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to load image from URL: \(url)")
            return
        }
        
        // Convert CGImage to NSImage for display
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        handleImportedImage(nsImage)
    }
    
    private func handleImportedImage(_ image: NSImage) {
        // Create a new layer for the imported image
        state.addLayer()
        if let newLayer = state.activeLayer {
            newLayer.name = "Imported Image"
        }
        
        // Store the image and set initial position (centered)
        importedImage = image
        let canvasSize = CGSize(width: state.canvasWidth, height: state.canvasHeight)
        
        // Get CGImage from NSImage
        var cgImage: CGImage?
        if let imageRep = image.representations.first as? NSBitmapImageRep {
            cgImage = imageRep.cgImage
        } else {
            // Fallback: create CGImage from NSImage
            let imageRect = NSRect(origin: .zero, size: image.size)
            if let imageRep = image.bestRepresentation(for: imageRect, context: nil, hints: nil) as? NSBitmapImageRep {
                cgImage = imageRep.cgImage
            } else {
                // Last resort: create from bitmap data
                cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
            }
        }
        
        if let img = cgImage {
            let imageSize = CGSize(width: img.width, height: img.height)
            let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height) * 0.8 // Scale to 80% to fit nicely
            let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            importedImagePosition = CGPoint(
                x: (canvasSize.width - scaledSize.width) / 2,
                y: (canvasSize.height - scaledSize.height) / 2
            )
        } else {
            importedImagePosition = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        }
    }
    
    private func placeImportedImage() {
        guard let image = importedImage,
              let activeLayer = state.activeLayer,
              let context = activeLayer.canvas.context else {
            return
        }
        
        // Get CGImage from NSImage
        var cgImage: CGImage?
        if let imageRep = image.representations.first as? NSBitmapImageRep {
            cgImage = imageRep.cgImage
        } else {
            cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        
        guard let img = cgImage else {
            print("Failed to get CGImage from NSImage")
            importedImage = nil
            return
        }
        
        // Draw the imported image at the current position
        let canvasSize = CGSize(width: state.canvasWidth, height: state.canvasHeight)
        let imageSize = CGSize(width: img.width, height: img.height)
        let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height) * 0.8
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        // The context is already flipped, so we can draw directly
        context.draw(img, in: CGRect(
            x: importedImagePosition.x,
            y: importedImagePosition.y,
            width: scaledSize.width,
            height: scaledSize.height
        ))
        
        // Clear the temporary image
        importedImage = nil
        state.canvasUpdateCounter += 1
        state.saveState()
    }
    #endif
    
    #if os(iOS)
    private func showImagePickerOptions() {
        let alert = UIAlertController(title: "Import Image", message: "Choose source", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.imagePickerSourceType = .camera
                self.showImagePicker = true
            })
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
                self.imagePickerSourceType = .photoLibrary
                self.showImagePicker = true
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                          y: rootViewController.view.bounds.midY,
                                          width: 0, height: 0)
            }
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func showIOSSaveError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Save Failed", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Find the root view controller to present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    // Helper class to bridge Objective-C callback for UIImageWriteToSavedPhotosAlbum
    private class IOSImageSaveHelper: NSObject {
        let onResult: (Error?) -> Void
        init(onResult: @escaping (Error?) -> Void) {
            self.onResult = onResult
        }
        @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            onResult(error)
        }
    }
    #endif
    #if os(macOS)
    private func performExport() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.performExport()
            }
            return
        }
        
        let baseSize = NSSize(width: state.canvasWidth, height: state.canvasHeight)
        let exportSizeMultiplier = exportSize.multiplier
        let exportSize = NSSize(width: baseSize.width * exportSizeMultiplier, height: baseSize.height * exportSizeMultiplier)
        
        guard let combinedImage = self.renderCombinedMacImage(at: exportSize, scale: exportSizeMultiplier) else {
            self.showSaveError("Failed to render image")
            return
        }
        
        // Create document based on selected format
        var document: AnyFileDocument?
        switch exportFormat {
        case .png:
            if let pngData = self.imageToPNGData(combinedImage) {
                document = AnyFileDocument(PNGDocument(data: pngData))
            } else {
                self.showSaveError("Failed to create PNG data")
                return
            }
        case .jpeg:
            if let jpegData = self.imageToJPEGData(combinedImage) {
                document = AnyFileDocument(JPEGDocument(data: jpegData))
            } else {
                self.showSaveError("Failed to create JPEG data")
                return
            }
        case .icns:
            if let icnsData = self.imageToICNSData(combinedImage) {
                document = AnyFileDocument(ICNSDocument(data: icnsData))
            } else {
                self.showSaveError("Failed to create ICNS data")
                return
            }
        }
        
        self.exportDocument = document
        
        DispatchQueue.main.async {
            guard self.exportDocument != nil else {
                self.showSaveError("Failed to create export document")
                return
            }
            self.showFileExporter = true
        }
    }
    
    private func renderCombinedMacImage(at size: NSSize, scale: CGFloat) -> NSImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = Int(size.width) * bytesPerPixel
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        // Scale context
        context.scaleBy(x: scale, y: scale)
        
        for layer in state.layers where layer.isVisible {
            if let cgImage = layer.canvas.createImage() {
                context.saveGState()
                context.setAlpha(CGFloat(layer.opacity))
                context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: state.canvasWidth, height: state.canvasHeight)))
                context.restoreGState()
            }
        }
        
        guard let cgImage = context.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: size)
    }
    
    private func renderCombinedMacImage() -> NSImage? {
        let size = NSSize(width: state.canvasWidth, height: state.canvasHeight)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = state.canvasWidth * bytesPerPixel
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: state.canvasWidth,
            height: state.canvasHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        for layer in state.layers where layer.isVisible {
            if let cgImage = layer.canvas.createImage() {
                context.saveGState()
                context.setAlpha(CGFloat(layer.opacity))
                context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: state.canvasWidth, height: state.canvasHeight)))
                context.restoreGState()
            }
        }
        
        guard let cgImage = context.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: size)
    }
    
    private func imageToPNGData(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
    }
    
    private func imageToJPEGData(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            return nil
        }
        return jpegData
    }
    
    private func imageToICNSData(_ image: NSImage) -> Data? {
        // ICNS creation requires multiple sizes
        let targetSizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
        var cgImages: [CGImage] = []
        
        for size in targetSizes {
            if let rep = bitmapRep(from: image, targetSize: NSSize(width: size, height: size)),
               let cgImage = rep.cgImage {
                cgImages.append(cgImage)
            }
        }
        
        guard !cgImages.isEmpty else { return nil }
        
        // Create temporary file for ICNS
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".icns")
        
        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, UTType.icns.identifier as CFString, cgImages.count, nil) else {
            return nil
        }
        
        for cgImage in cgImages {
            CGImageDestinationAddImage(destination, cgImage, nil)
        }
        
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return try? Data(contentsOf: tempURL)
    }
    
    private func bitmapRep(from image: NSImage, targetSize: NSSize) -> NSBitmapImageRep? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        rep.size = targetSize
        
        NSGraphicsContext.saveGraphicsState()
        if let graphicsContext = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = graphicsContext
            image.draw(
                in: NSRect(origin: .zero, size: targetSize),
                from: NSRect(origin: .zero, size: image.size),
                operation: .copy,
                fraction: 1.0,
                respectFlipped: true,
                hints: nil
            )
        }
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }
    
    private func showSaveError(_ message: String) {
        // Ensure NSAlert is shown on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showSaveError(message)
            }
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Save Failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showSaveSuccess(at url: URL) {
        // Ensure NSAlert is shown on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showSaveSuccess(at: url)
            }
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Image Saved"
        alert.informativeText = "Saved to: \(url.path)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Show in Finder")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            let fileURL = URL(fileURLWithPath: url.path)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
    
    
    private func defaultFileName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let ext = exportFormat.fileExtension
        return "stickers-\(timestamp).\(ext)"
    }
    
    private func convertExportFormat(at url: URL) {
        // Read the PNG data that was saved
        guard let pngData = try? Data(contentsOf: url),
              let nsImage = NSImage(data: pngData) else {
            self.showSaveError("Failed to read saved file")
            return
        }
        
        // Convert to requested format
        let finalData: Data?
        let finalURL: URL
        
        switch exportFormat {
        case .png:
            finalData = pngData
            finalURL = url
        case .jpeg:
            finalData = self.imageToJPEGData(nsImage)
            finalURL = url.deletingPathExtension().appendingPathExtension("jpg")
        case .icns:
            finalData = self.imageToICNSData(nsImage)
            finalURL = url.deletingPathExtension().appendingPathExtension("icns")
        }
        
        guard let data = finalData else {
            self.showSaveError("Failed to convert to \(exportFormat.rawValue)")
            return
        }
        
        // Delete original PNG file if format changed
        if exportFormat != .png {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Write final file
        do {
            try data.write(to: finalURL)
            self.showSaveSuccess(at: finalURL)
        } catch {
            self.showSaveError("Failed to save: \(error.localizedDescription)")
        }
    }
#endif
}

// MARK: - Export Options View

struct ExportOptionsView: View {
    @Binding var exportFormat: ExportFormat
    @Binding var exportSize: ExportSize
    let onExport: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Export Size") {
                    Picker("Size", selection: $exportSize) {
                        ForEach(ExportSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Export Options")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        onExport()
                        dismiss()
                    }
                }
            }
            #if os(macOS)
            .frame(width: 400, height: 200)
            #endif
        }
    }
}

// MARK: - Export Format & Size

enum ExportFormat: String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case icns = "ICNS"
    
    var contentType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .icns: return .icns
        }
    }
    
    var fileExtension: String {
        return rawValue.lowercased()
    }
}

enum ExportSize: String, CaseIterable {
    case halfX = "0.5x"
    case oneX = "1x"
    case twoX = "2x"
    case fourX = "4x"
    
    var multiplier: CGFloat {
        switch self {
        case .halfX: return 0.5
        case .oneX: return 1.0
        case .twoX: return 2.0
        case .fourX: return 4.0
        }
    }
    
    var displayName: String {
        return rawValue
    }
}

#if os(macOS)
// MARK: - File Documents

/// FileDocument wrapper for PNG image data
struct PNGDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    static var writableContentTypes: [UTType] { [.png] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

/// FileDocument wrapper for JPEG image data
struct JPEGDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.jpeg] }
    static var writableContentTypes: [UTType] { [.jpeg] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

/// FileDocument wrapper for ICNS image data
struct ICNSDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.icns] }
    static var writableContentTypes: [UTType] { [.icns] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

/// Type-erased wrapper for FileDocument to support multiple formats
enum AnyFileDocument: FileDocument {
    case png(PNGDocument)
    case jpeg(JPEGDocument)
    case icns(ICNSDocument)
    
    static var readableContentTypes: [UTType] { [.png, .jpeg, .icns] }
    static var writableContentTypes: [UTType] { [.png, .jpeg, .icns] }
    
    init(_ doc: PNGDocument) { self = .png(doc) }
    init(_ doc: JPEGDocument) { self = .jpeg(doc) }
    init(_ doc: ICNSDocument) { self = .icns(doc) }
    
    init(configuration: ReadConfiguration) throws {
        // Try to read as PNG first
        if let data = configuration.file.regularFileContents {
            if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { // PNG signature
                self = .png(try PNGDocument(configuration: configuration))
            } else if data.starts(with: [0xFF, 0xD8, 0xFF]) { // JPEG signature
                self = .jpeg(try JPEGDocument(configuration: configuration))
            } else {
                self = .png(try PNGDocument(configuration: configuration))
            }
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        switch self {
        case .png(let doc): return try doc.fileWrapper(configuration: configuration)
        case .jpeg(let doc): return try doc.fileWrapper(configuration: configuration)
        case .icns(let doc): return try doc.fileWrapper(configuration: configuration)
        }
    }
}
#endif

#if os(iOS)
// MARK: - ImagePicker

/// Wrapper for UIImagePickerController to present image picker in SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onDismiss: { dismiss() })
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let onDismiss: () -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void, onDismiss: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onDismiss = onDismiss
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            onDismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onDismiss()
        }
    }
}
#endif

