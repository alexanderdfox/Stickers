//
//  ToolbarView.swift
//  Stickers
//
//  Toolbar interface for selecting tools, colors, brush settings, effects,
//  fill patterns, stamp settings, and layer management.
//  Provides a comprehensive sidebar UI for all drawing controls.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - System Fonts Helper

struct SystemFonts {
    static var availableFonts: [String] {
        var fonts: [String] = []
        
        #if canImport(AppKit)
        // macOS system fonts
        if let fontFamilies = NSFontManager.shared.availableFontFamilies as? [String] {
            fonts = fontFamilies.sorted()
        }
        #elseif canImport(UIKit)
        // iOS system fonts
        fonts = UIFont.familyNames.sorted()
        #endif
        
        // Filter to common/well-known fonts and add some defaults
        let commonFonts = [
            "Arial",
            "Arial Black",
            "Arial Narrow",
            "Avenir",
            "Avenir Next",
            "Baskerville",
            "Chalkboard",
            "Chalkboard SE",
            "Comic Sans MS",
            "Courier",
            "Courier New",
            "Georgia",
            "Helvetica",
            "Helvetica Neue",
            "Impact",
            "Menlo",
            "Monaco",
            "Palatino",
            "Papyrus",
            "Times New Roman",
            "Trebuchet MS",
            "Verdana"
        ]
        
        // Start with common fonts, then add others
        var result = commonFonts.filter { fonts.contains($0) }
        
        // Add other fonts that aren't in the common list
        for font in fonts {
            if !result.contains(font) {
                result.append(font)
            }
        }
        
        return result
    }
}

// MARK: - KeyboardShortcutModifier

/// View modifier for conditionally applying keyboard shortcuts
struct KeyboardShortcutModifier: ViewModifier {
    let keyboardShortcut: String?
    
    func body(content: Content) -> some View {
        if let shortcut = keyboardShortcut, let firstChar = shortcut.first {
            content.keyboardShortcut(KeyEquivalent(firstChar), modifiers: [])
        } else {
            content
        }
    }
}

// MARK: - View Extension

/// Extension for conditional view modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - ToolbarView

/// Main toolbar view containing all drawing controls
/// Includes tools, colors, brush size, effects, patterns, stamps, and layers
struct ToolbarView: View {
    @ObservedObject var state: DrawingState
    
    private var colorButtonSize: CGFloat {
        #if os(macOS)
        return 36
        #else
        return 44
        #endif
    }
    
    private var stampButtonBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Tools Section
                ToolSection(title: "🛠️ Tools") {
                    ForEach(ToolType.allCases.filter { tool in
                        ![.selectCircle, .selectSquare].contains(tool)
                    }, id: \.self) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: state.currentTool == tool,
                            action: {
                                AppPreferences.shared.playSound(.click)
                                state.currentTool = tool
                            }
                        )
                    }
                }
                
                // Grid and Ruler Section
                ToolSection(title: "📐 Guides") {
                    Toggle(isOn: $state.showGrid) {
                        Label("Grid", systemImage: "grid")
                            .font(.system(size: 14))
                    }
                    .toggleStyle(.switch)
                    
                    if state.showGrid {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Grid Size: \(Int(state.gridSize))px")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Slider(value: $state.gridSize, in: 5...100, step: 5)
                                .frame(height: 20)
                        }
                        .padding(.leading, 8)
                    }
                    
                    Toggle(isOn: $state.showRuler) {
                        Label("Ruler", systemImage: "ruler")
                            .font(.system(size: 14))
                    }
                    .toggleStyle(.switch)
                }
                
                // Selection Tools
                ToolSection(title: "✂️ Selection") {
                    ToolButton(
                        tool: .selectCircle,
                        isSelected: state.currentTool == .selectCircle,
                        action: {
                            AppPreferences.shared.playSound(.click)
                            state.currentTool = .selectCircle
                        }
                    )
                    ToolButton(
                        tool: .selectSquare,
                        isSelected: state.currentTool == .selectSquare,
                        action: {
                            AppPreferences.shared.playSound(.click)
                            state.currentTool = .selectSquare
                        }
                    )
                }
                
                // Colors Section
                ToolSection(title: "🎨 Colors") {
                    #if os(macOS)
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Primary")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            ColorPicker("", selection: $state.currentColor)
                                .labelsHidden()
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Secondary")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            ColorPicker("", selection: $state.secondaryColor)
                                .labelsHidden()
                        }
                    }
                    #else
                    VStack(spacing: 12) {
                        HStack {
                            Text("Primary")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            ColorPicker("", selection: $state.currentColor)
                                .labelsHidden()
                                .frame(width: 44, height: 44)
                        }
                        HStack {
                            Text("Secondary")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            ColorPicker("", selection: $state.secondaryColor)
                                .labelsHidden()
                                .frame(width: 44, height: 44)
                        }
                    }
                    #endif
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: colorButtonSize))], spacing: 8) {
                        ForEach(presetColors, id: \.self) { color in
                            ColorButton(color: color, isSelected: state.currentColor == color) {
                                state.currentColor = color
                            }
                        }
                    }
                }
                
                // Brush Size
                ToolSection(title: "📏 Brush Size") {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Slider(value: $state.brushSize, in: 1...50)
                                .controlSize(.small)
                            Text("\(Int(state.brushSize))")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.accentColor)
                                .frame(width: 35, alignment: .trailing)
                        }
                        
                        // Visual brush size indicator
                        Circle()
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: CGFloat(state.brushSize), height: CGFloat(state.brushSize))
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                
                // Effects
                ToolSection(title: "✨ Effects") {
                    VStack(spacing: 8) {
                        Toggle(isOn: $state.rainbowMode) {
                            Label {
                                Text("Rainbow")
                                    .font(.system(size: 12, weight: .medium))
                            } icon: {
                                Text("🌈")
                                    .font(.system(size: 16))
                            }
                        }
                        Toggle(isOn: $state.sparkleMode) {
                            Label {
                                Text("Sparkle")
                                    .font(.system(size: 12, weight: .medium))
                            } icon: {
                                Text("✨")
                                    .font(.system(size: 16))
                            }
                        }
                        Toggle(isOn: $state.mirrorMode) {
                            Label {
                                Text("Mirror")
                                    .font(.system(size: 12, weight: .medium))
                            } icon: {
                                Text("🪞")
                                    .font(.system(size: 16))
                            }
                        }
                    }
                }
                
                // Fill Pattern
                ToolSection(title: "🎨 Fill Pattern") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                        ForEach(FillPattern.allCases, id: \.self) { pattern in
                            PatternButton(
                                pattern: pattern,
                                isSelected: state.fillPattern == pattern,
                                action: { state.fillPattern = pattern }
                            )
                        }
                    }
                }
                
                // Stamp Settings
                if state.currentTool == .stamp {
                    ToolSection(title: "🎯 Stamp") {
                        // Emoji picker button
                        Button(action: { }) {
                            HStack {
                                Text(state.selectedEmoji)
                                    .font(.system(size: 32))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(stampButtonBackground)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Select Emoji")
                        
                        // Emoji text input for any Unicode character
                        TextField("Enter any emoji or text", text: $state.selectedEmoji)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 14))
                            .help("Type any emoji or Unicode character")
                        
                        // Font selection with dropdown
                        HStack {
                            Text("Font:")
                                #if os(macOS)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                #else
                                .font(.system(size: 13, weight: .medium))
                                #endif
                            Picker("Font", selection: $state.selectedFont) {
                                ForEach(SystemFonts.availableFonts, id: \.self) { fontName in
                                    Text(fontName)
                                        .tag(fontName)
                                }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.small)
                            #if os(macOS)
                            .frame(maxWidth: 200)
                            #endif
                            .onAppear {
                                // Ensure selected font is in the list, otherwise use first available
                                let availableFonts = SystemFonts.availableFonts
                                if !availableFonts.contains(state.selectedFont) {
                                    state.selectedFont = availableFonts.first ?? "Arial"
                                }
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text("Rotation:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Slider(value: $state.stampRotation, in: 0...360)
                                .controlSize(.small)
                            Text("\(Int(state.stampRotation))°")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                        
                        Button("Reset Rotation") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                state.stampRotation = 0
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        #if os(macOS)
                        .help("Reset to 0° (R)")
                        .keyboardShortcut("r", modifiers: [])
                        #endif
                    }
                }
                
                // Arc Settings
                if state.currentTool == .arc {
                    ToolSection(title: "🌙 Arc") {
                        HStack(spacing: 8) {
                            Text("Angle:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Slider(value: $state.arcSweepAngle, in: 0...360)
                                .controlSize(.small)
                            Text("\(Int(state.arcSweepAngle))°")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                        
                        Button("Reset to 90°") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                state.arcSweepAngle = 90
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Reset to 90°")
                    }
                }
                
                // Canvas Size
                ToolSection(title: "📐 Canvas Size") {
                    Picker("Size", selection: Binding(
                        get: { "\(state.canvasWidth)x\(state.canvasHeight)" },
                        set: { value in
                            if let size = parseSize(value) {
                                #if os(macOS)
                                let alert = NSAlert()
                                alert.messageText = "Resize Canvas"
                                alert.informativeText = "Changing canvas size will preserve existing content (top-left aligned). Continue?"
                                alert.alertStyle = .informational
                                alert.addButton(withTitle: "Resize")
                                alert.addButton(withTitle: "Cancel")
                                
                                if alert.runModal() == .alertFirstButtonReturn {
                                    state.setCanvasSize(width: size.width, height: size.height)
                                }
                                #else
                                // iOS: Direct resize
                                state.setCanvasSize(width: size.width, height: size.height)
                                #endif
                            }
                        }
                    )) {
                        Text("800×600").tag("800x600")
                        Text("1024×768").tag("1024x768")
                        Text("1280×720").tag("1280x720")
                        Text("1920×1080").tag("1920x1080")
                        Text("640×480").tag("640x480")
                        Text("512×512").tag("512x512")
                        Text("1080×1080").tag("1080x1080")
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    #if os(macOS)
                    .help("Change canvas size")
                    #endif
                }
                
                // Layer Panel
                LayerPanelView(state: state)
            }
            .padding(toolbarViewPadding)
        }
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #endif
    }
    
    private var toolbarViewPadding: CGFloat {
        #if os(macOS)
        return 12
        #else
        return 16
        #endif
    }
    
    private var presetColors: [Color] {
        [
            .red, .orange, .yellow, .green, .blue,
            .purple, .pink, .black, .white, .cyan,
            .brown, .gray
        ]
    }
    
    private func parseSize(_ value: String) -> (width: Int, height: Int)? {
        // Security: Validate input string length to prevent DoS
        guard value.count > 0, value.count < 100 else {
            return nil
        }
        
        // Security: Sanitize input - only allow digits and 'x'
        let allowedCharacters = CharacterSet(charactersIn: "0123456789x")
        guard value.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return nil
        }
        
        let components = value.split(separator: "x")
        guard components.count == 2,
              components[0].count > 0, components[0].count < 10, // Reasonable length
              components[1].count > 0, components[1].count < 10, // Reasonable length
              let width = Int(components[0]),
              let height = Int(components[1]),
              width > 0, height > 0,
              width <= 10000, height <= 10000, // Enforce max dimensions
              width * height <= 100_000_000, // Prevent memory exhaustion
              width <= Int.max / 4, height <= Int.max / 4 else { // Prevent integer overflow
            return nil
        }
        return (width: width, height: height)
    }
}

struct ToolSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            content
        }
        .padding(12)
        .background(toolSectionBackground)
        .cornerRadius(8)
    }
    
    private var toolSectionBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }
}

struct ToolButton: View {
    let tool: ToolType
    let isSelected: Bool
    let action: () -> Void
    
    private var shortcutBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .tertiarySystemBackground)
        #endif
    }
    
    private var toolHelpText: String {
        if let shortcut = tool.keyboardShortcut {
            return "\(tool.name) (\(shortcut))"
        } else {
            return tool.name
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
        }) {
            HStack(spacing: 8) {
                Text(tool.icon)
                    .font(.system(size: 16))
                Text(tool.name)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                if let shortcut = tool.keyboardShortcut {
                    Text(shortcut)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        #if os(macOS)
        .help(toolHelpText)
        .modifier(KeyboardShortcutModifier(keyboardShortcut: tool.keyboardShortcut))
        #endif
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    private var colorButtonFrame: CGFloat {
        #if os(macOS)
        return 36
        #else
        return 44
        #endif
    }
    
    private var colorButtonStroke: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color(uiColor: .separator)
        #endif
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
                Circle()
                .fill(color)
                .frame(width: colorButtonFrame, height: colorButtonFrame)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.accentColor : colorButtonStroke,
                            lineWidth: isSelected ? 3 : 1
                        )
                )
                .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct PatternButton: View {
    let pattern: FillPattern
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(patternColor(for: pattern))
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                )
        }
    }
    
    private func patternColor(for pattern: FillPattern) -> Color {
        switch pattern {
        case .solid: return .purple
        case .transparent: return .white
        case .horizontal: return .blue.opacity(0.5)
        case .vertical: return .green.opacity(0.5)
        case .diagonal: return .orange.opacity(0.5)
        case .checkerboard: return .gray.opacity(0.3)
        case .dots: return .pink.opacity(0.5)
        }
    }
}

struct LayerPanelView: View {
    @ObservedObject var state: DrawingState
    
    private var layerButtonSize: CGFloat {
        #if os(macOS)
        return 12
        #else
        return 14
        #endif
    }
    
    private var layerButtonFrame: CGFloat {
        #if os(macOS)
        return 28
        #else
        return 44
        #endif
    }
    
    var body: some View {
        ToolSection(title: "📑 Layers") {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.addLayer()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: layerButtonSize, weight: .medium))
                            .frame(width: layerButtonFrame, height: layerButtonFrame)
                    }
                    #if os(macOS)
                    .buttonStyle(.borderless)
                    .help("Add Layer")
                    #else
                    .buttonStyle(.plain)
                    #endif
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.deleteActiveLayer()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: layerButtonSize, weight: .medium))
                            .frame(width: layerButtonFrame, height: layerButtonFrame)
                    }
                    #if os(macOS)
                    .buttonStyle(.borderless)
                    .disabled(state.layers.count <= 1)
                    .help("Delete Layer")
                    #else
                    .buttonStyle(.plain)
                    .disabled(state.layers.count <= 1)
                    #endif
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.duplicateActiveLayer()
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: layerButtonSize, weight: .medium))
                            .frame(width: layerButtonFrame, height: layerButtonFrame)
                    }
                    #if os(macOS)
                    .buttonStyle(.borderless)
                    .help("Duplicate Layer")
                    #else
                    .buttonStyle(.plain)
                    #endif
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.mergeDown()
                        }
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: layerButtonSize, weight: .medium))
                            .frame(width: layerButtonFrame, height: layerButtonFrame)
                    }
                    #if os(macOS)
                    .buttonStyle(.borderless)
                    .disabled(state.activeLayerIndex == 0)
                    .help("Merge Down")
                    #else
                    .buttonStyle(.plain)
                    .disabled(state.activeLayerIndex == 0)
                    #endif
                }
                .padding(.bottom, 4)
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(Array(state.layers.enumerated()), id: \.element.id) { index, layer in
                            LayerItemView(
                                layer: layer,
                                isActive: index == state.activeLayerIndex,
                                action: { state.activeLayerIndex = index }
                            )
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
    }
}

struct LayerItemView: View {
    @ObservedObject var layer: DrawingLayer
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    action()
                }
            }) {
                HStack(spacing: 8) {
                    Toggle("", isOn: $layer.isVisible)
                        .labelsHidden()
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #else
                        .toggleStyle(.switch)
                    #endif
                    
                    TextField("Layer Name", text: $layer.name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .disabled(!isActive)
                    
                    Spacer()
                    
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isActive ? Color.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            // Opacity slider (only show for active layer)
            if isActive {
                HStack(spacing: 6) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Slider(value: $layer.opacity, in: 0...1)
                        .tint(.accentColor)
                    Text("\(Int(layer.opacity * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) var dismiss
    @State private var customEmoji: String = ""
    
    private var emojiPickerSectionBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Custom emoji input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Any Emoji or Text")
                        .font(.system(size: 13, weight: .semibold))
                    
                    TextField("Type any Unicode character or emoji", text: $customEmoji)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 20))
                        .onSubmit {
                            if !customEmoji.isEmpty {
                                selectedEmoji = customEmoji
                                dismiss()
                            }
                        }
                    
                    Button("Use This") {
                        if !customEmoji.isEmpty {
                            HapticFeedback.selection()
                            selectedEmoji = customEmoji
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(emojiPickerSectionBackground)
                .cornerRadius(8)
                
                Divider()
                
                // Preset emoji grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 8) {
                        ForEach(EmojiData.categories.flatMap { $0.emojis }, id: \.self) { emoji in
                            Button(action: {
                                HapticFeedback.selection()
                                selectedEmoji = emoji
                                dismiss()
                            }) {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 50, height: 50)
                                    .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedEmoji == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Emoji")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        #if os(iOS)
                        .frame(minWidth: 44, minHeight: 44)
                        #endif
                }
            }
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 500)
            #endif
            .onAppear {
                customEmoji = selectedEmoji
            }
        }
    }
}

// MARK: - Ruler Overlay

struct RulerOverlay: View {
    let canvasWidth: Int
    let canvasHeight: Int
    
    private let rulerHeight: CGFloat = 20
    private let tickSpacing: CGFloat = 20
    private let majorTickSpacing: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 0) {
            // Top ruler (horizontal)
            HStack(spacing: 0) {
                // Corner square
                ZStack {
                    Rectangle()
                        .fill(Color(white: 0.95))
                        .frame(width: rulerHeight, height: rulerHeight)
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        .frame(width: rulerHeight, height: rulerHeight)
                }
                
                // Horizontal ruler
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Color(white: 0.95))
                            .frame(height: rulerHeight)
                        
                        // Draw tick marks
                        ForEach(0..<Int(geometry.size.width / tickSpacing) + 1, id: \.self) { i in
                            let x = CGFloat(i) * tickSpacing
                            let isMajor = i % Int(majorTickSpacing / tickSpacing) == 0
                            let tickHeight: CGFloat = isMajor ? rulerHeight * 0.6 : rulerHeight * 0.4
                            
                            Path { path in
                                path.move(to: CGPoint(x: x, y: rulerHeight))
                                path.addLine(to: CGPoint(x: x, y: rulerHeight - tickHeight))
                            }
                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                            
                            // Draw numbers on major ticks
                            if isMajor && x < geometry.size.width - 20 {
                                Text("\(Int(x))")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                    .position(x: x + 2, y: rulerHeight * 0.3)
                            }
                        }
                        
                        Rectangle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                            .frame(height: rulerHeight)
                    }
                }
            }
            .frame(height: rulerHeight)
            
            HStack(spacing: 0) {
                // Left ruler (vertical)
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ZStack {
                            Rectangle()
                                .fill(Color(white: 0.95))
                                .frame(width: rulerHeight)
                            
                            // Draw tick marks
                            ForEach(0..<Int(geometry.size.height / tickSpacing) + 1, id: \.self) { i in
                                let y = CGFloat(i) * tickSpacing
                                let isMajor = i % Int(majorTickSpacing / tickSpacing) == 0
                                let tickWidth: CGFloat = isMajor ? rulerHeight * 0.6 : rulerHeight * 0.4
                                
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: tickWidth, y: y))
                                }
                                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                
                                // Draw numbers on major ticks
                                if isMajor && y < geometry.size.height - 15 {
                                    Text("\(Int(y))")
                                        .font(.system(size: 8))
                                        .foregroundColor(.gray)
                                        .rotationEffect(.degrees(-90))
                                        .position(x: rulerHeight * 0.3, y: y)
                                }
                            }
                            
                            Rectangle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                .frame(width: rulerHeight)
                        }
                    }
                    .frame(width: rulerHeight)
                }
                
                // Canvas area (spacer)
                Spacer()
            }
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Keyboard Shortcuts")
                        .font(.system(size: 18, weight: .bold))
                    
                    HelpRow(shortcut: "1-9, 0", description: "Select tools")
                    HelpRow(shortcut: "⌘Z", description: "Undo")
                    HelpRow(shortcut: "⌘⇧Z", description: "Redo")
                    HelpRow(shortcut: "R", description: "Reset stamp rotation")
                    HelpRow(shortcut: "+/-", description: "Zoom in/out")
                    
                    Text("Tools")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.top, 8)
                    
                    Text("• Pencil: Freehand drawing\n• Line: Straight lines\n• Eraser: Remove content\n• Fill: Flood fill areas\n• Spray: Spray paint effect\n• Shapes: Circle, Square, Triangle, Star\n• Stamp: Emoji and text stamps")
                        .font(.system(size: 13))
                    
                    Text("Effects")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.top, 8)
                    
                    Text("• Rainbow: Color-changing strokes\n• Sparkle: Add sparkles while drawing\n• Mirror: Mirror mode")
                        .font(.system(size: 13))
                }
                .padding()
            }
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        #if os(iOS)
                        .frame(minWidth: 44, minHeight: 44)
                        #endif
                }
            }
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 400)
            #endif
        }
    }
}

struct HelpRow: View {
    let shortcut: String
    let description: String
    
    private var shortcutBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .tertiarySystemBackground)
        #endif
    }
    
    private var shortcutStroke: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color(uiColor: .separator)
        #endif
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(shortcut)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(shortcutBackground)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(shortcutStroke, lineWidth: 0.5)
                )
            Text(description)
                .font(.system(size: 13))
            Spacer()
        }
    }
}

