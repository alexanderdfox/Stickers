//
//  ContentView.swift
//  EmojiPix
//
//  Created by Alexander Fox on 11/20/25.
//

//
//  ContentView.swift
//  EmojiPix
//

import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
import ImageIO
#elseif canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var state = DrawingState()
    @State private var showSidebar = true
    @State private var showEmojiPicker = false
    @State private var showHelp = false
    
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
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
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
                    CanvasView(state: state)
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
                    CanvasView(state: state)
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
            
            Text("🎨 EmojiPix")
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
            
            // Clear
            Button(action: clearCanvas) {
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
            
            // Save
            Button(action: {
                HapticFeedback.medium()
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
        let size = CGSize(width: state.canvasWidth, height: state.canvasHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            for layer in state.layers where layer.isVisible {
                if let cgImage = layer.canvas.createImage() {
                    context.cgContext.saveGState()
                    context.cgContext.setAlpha(CGFloat(layer.opacity))
                    context.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
                    context.cgContext.restoreGState()
                }
            }
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        #elseif os(macOS)
        guard let combinedImage = renderCombinedMacImage() else { return }
        presentSavePanel(for: combinedImage)
        #endif
    }
#if os(macOS)
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
    
    private func presentSavePanel(for image: NSImage) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .icns]
        savePanel.canCreateDirectories = true
        savePanel.allowsOtherFileTypes = false
        savePanel.nameFieldStringValue = defaultFileName()
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            // Ensure extension matches selection
            let lowerExt = url.pathExtension.lowercased()
            var finalURL = url
            if lowerExt.isEmpty {
                finalURL = url.appendingPathExtension("png")
            }
            do {
                try save(image: image, to: finalURL)
            } catch {
                NSLog("EmojiPix save failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func save(image: NSImage, to url: URL) throws {
        switch url.pathExtension.lowercased() {
        case "icns":
            try saveAsICNS(image: image, url: url)
        default:
            try saveAsPNG(image: image, url: url)
        }
    }
    
    private func saveAsPNG(image: NSImage, url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw ExportError.pngEncodingFailed
        }
        try pngData.write(to: url)
    }
    
    private func saveAsICNS(image: NSImage, url: URL) throws {
        let targetSizes: [CGFloat] = [64, 128, 256]
        var cgImages: [CGImage] = []
        
        for size in targetSizes {
            if let rep = bitmapRep(from: image, targetSize: NSSize(width: size, height: size)),
               let cgImage = rep.cgImage {
                cgImages.append(cgImage)
            }
        }
        
        guard !cgImages.isEmpty,
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.icns.identifier as CFString, cgImages.count, nil) else {
            throw ExportError.icnsEncodingFailed
        }
        
        for cgImage in cgImages {
            CGImageDestinationAddImage(destination, cgImage, nil)
        }
        
        if !CGImageDestinationFinalize(destination) {
            throw ExportError.icnsEncodingFailed
        }
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
    
    private func defaultFileName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "emojipix-\(timestamp)"
    }
    
    enum ExportError: Error {
        case pngEncodingFailed
        case icnsEncodingFailed
    }
#endif
}

