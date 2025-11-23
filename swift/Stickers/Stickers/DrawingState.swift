//
//  DrawingState.swift
//  Stickers
//
//  Manages the application's drawing state, including tools, colors, layers,
//  undo/redo history, canvas properties, and all drawing-related settings.
//  This is the central state object observed by SwiftUI views.
//

import SwiftUI
import CoreGraphics
import Combine

/// Main state object for the drawing application
/// Manages canvas properties, tools, layers, history, and all drawing settings
class DrawingState: ObservableObject {
    // MARK: - Canvas Properties
    @Published var canvasWidth: Int = 800
    @Published var canvasHeight: Int = 600
    @Published var canvasUpdateCounter: Int = 0 // Force canvas refresh on changes
    
    // MARK: - Tool Properties
    @Published var currentTool: ToolType = .pencil
    @Published var brushSize: Double = 5
    @Published var currentColor: Color = .red
    @Published var secondaryColor: Color = .white
    @Published var fillPattern: FillPattern = .solid
    
    // MARK: - Effects
    @Published var rainbowMode: Bool = false
    @Published var sparkleMode: Bool = false
    @Published var mirrorMode: Bool = false
    
    // MARK: - Stamp Properties
    @Published var selectedEmoji: String = "😀"
    @Published var stampRotation: Double = 0
    @Published var selectedFont: String = "Arial"
    @Published var textCase: TextCase = .upper
    
    // MARK: - Arc Properties
    @Published var arcSweepAngle: Double = 90
    
    // MARK: - Zoom
    @Published var canvasZoom: Double = 1.0
    
    // MARK: - Layers
    @Published var layers: [DrawingLayer] = []
    @Published var activeLayerIndex: Int = 0
    
    // MARK: - Selection
    @Published var hasSelection: Bool = false
    @Published var selectionBounds: CGRect = .zero
    @Published var clipboard: CGImage?
    
    // MARK: - Selection Operations
    
    /// Copy the selected region to clipboard
    func copySelection() {
        guard hasSelection, let layer = activeLayer else { return }
        
        let bounds = selectionBounds
        let x = Int(bounds.origin.x)
        let y = Int(bounds.origin.y)
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        
        guard x >= 0, y >= 0, width > 0, height > 0,
              x + width <= canvasWidth, y + height <= canvasHeight,
              let sourceImage = layer.canvas.createImage() else {
            return
        }
        
        // Extract the selected region
        // Note: CGImage uses bottom-left origin, but our coordinates are top-left
        // So we need to flip the Y coordinate
        let flippedY = sourceImage.height - y - height
        if let croppedImage = sourceImage.cropping(to: CGRect(x: x, y: flippedY, width: width, height: height)) {
            clipboard = croppedImage
        }
    }
    
    /// Cut the selected region (copy and clear)
    func cutSelection() {
        guard hasSelection, let layer = activeLayer else { return }
        
        // Copy first
        copySelection()
        
        // Then clear the selected region
        let bounds = selectionBounds
        guard let context = layer.canvas.context else { return }
        
        // Account for flipped coordinate system
        // The context is flipped, so we need to adjust the Y coordinate
        let flippedY = CGFloat(canvasHeight) - bounds.origin.y - bounds.height
        let flippedBounds = CGRect(
            x: bounds.origin.x,
            y: flippedY,
            width: bounds.width,
            height: bounds.height
        )
        
        context.setBlendMode(.clear)
        context.fill(flippedBounds)
        context.setBlendMode(.normal)
        
        saveState()
    }
    
    /// Paste the clipboard content at the specified point
    /// - Parameter point: The point to paste at (top-left corner)
    func pasteSelection(at point: CGPoint) {
        guard let image = clipboard, let layer = activeLayer,
              let context = layer.canvas.context else { return }
        
        let x = max(0, min(Int(point.x), canvasWidth))
        let y = max(0, min(Int(point.y), canvasHeight))
        
        // Account for flipped coordinate system
        // The context is flipped, so we need to adjust the Y coordinate
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        let flippedY = CGFloat(canvasHeight) - CGFloat(y) - imageHeight
        
        // Draw the clipboard image at the paste location
        context.draw(image, in: CGRect(x: CGFloat(x), y: flippedY, width: imageWidth, height: imageHeight))
        
        // Update selection to the pasted region (in normal coordinates)
        selectionBounds = CGRect(x: CGFloat(x), y: CGFloat(y), width: imageWidth, height: imageHeight)
        hasSelection = true
        
        saveState()
    }
    
    /// Clear the current selection
    func clearSelection() {
        hasSelection = false
        selectionBounds = .zero
    }
    
    // MARK: - History
    private var history: [DrawingSnapshot] = []
    private var historyIndex: Int = -1
    private let maxHistory = 50
    
    // MARK: - Initialization
    init() {
        initializeLayers()
    }
    
    // MARK: - Layer Management
    
    /// Initialize the layer system with a default background layer
    func initializeLayers() {
        layers = []
        let background = DrawingLayer(name: "Background", width: canvasWidth, height: canvasHeight)
        background.canvas.clear(color: .white)
        layers.append(background)
        activeLayerIndex = 0
        saveState()
    }
    
    /// Get the currently active layer
    var activeLayer: DrawingLayer? {
        guard activeLayerIndex < layers.count else { return nil }
        return layers[activeLayerIndex]
    }
    
    /// Add a new empty layer to the canvas
    func addLayer() {
        let newLayer = DrawingLayer(name: "Layer \(layers.count + 1)", width: canvasWidth, height: canvasHeight)
        layers.append(newLayer)
        activeLayerIndex = layers.count - 1
        saveState()
    }
    
    /// Delete the active layer (cannot delete if only one layer remains)
    func deleteActiveLayer() {
        guard layers.count > 1,
              activeLayerIndex >= 0,
              activeLayerIndex < layers.count else { return }
        
        layers.remove(at: activeLayerIndex)
        
        // Adjust activeLayerIndex if needed
        if activeLayerIndex >= layers.count {
            activeLayerIndex = max(0, layers.count - 1)
        }
        
        saveState()
    }
    
    /// Load an image as the background layer
    /// - Parameters:
    ///   - cgImage: The CGImage to load
    func loadImageAsBackground(_ cgImage: CGImage) {
        // Set canvas size to match image
        canvasWidth = cgImage.width
        canvasHeight = cgImage.height
        
        // Store existing layers (except background) to preserve them
        var existingLayers: [DrawingLayer] = []
        if layers.count > 1 {
            // Keep all layers except the first (background)
            existingLayers = Array(layers.dropFirst())
        }
        
        // Create new background layer with image
        let background = DrawingLayer(name: "Background", width: canvasWidth, height: canvasHeight)
        
        // Draw the image onto the background layer
        if let context = background.canvas.context {
            // The context is already flipped, so we can draw directly
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        }
        
        // Rebuild layers array with new background and existing layers
        layers = [background]
        
        // Recreate existing layers with new canvas size
        for oldLayer in existingLayers {
            let newLayer = DrawingLayer(name: oldLayer.name, width: canvasWidth, height: canvasHeight)
            newLayer.isVisible = oldLayer.isVisible
            newLayer.opacity = oldLayer.opacity
            
            // Try to copy old content if it fits
            if let oldImage = oldLayer.canvas.createImage(),
               let newContext = newLayer.canvas.context {
                let sourceWidth = min(oldLayer.canvas.width, canvasWidth)
                let sourceHeight = min(oldLayer.canvas.height, canvasHeight)
                let drawRect = CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight)
                newContext.draw(oldImage, in: drawRect)
            }
            
            layers.append(newLayer)
        }
        
        activeLayerIndex = 0
        canvasUpdateCounter += 1
        saveState()
    }
    
    /// Duplicate the active layer with all its content
    func duplicateActiveLayer() {
        guard let layer = activeLayer,
              activeLayerIndex >= 0,
              activeLayerIndex < layers.count else { return }
        
        let newLayer = DrawingLayer(name: "\(layer.name) Copy", width: canvasWidth, height: canvasHeight)
        newLayer.isVisible = layer.isVisible
        newLayer.opacity = layer.opacity
        
        // Copy canvas content
        if let image = layer.canvas.createImage(),
           let context = newLayer.canvas.context {
            context.draw(image, in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        }
        
        let insertIndex = min(activeLayerIndex + 1, layers.count)
        layers.insert(newLayer, at: insertIndex)
        activeLayerIndex = insertIndex
        saveState()
    }
    
    /// Merge the active layer down into the layer below it
    func mergeDown() {
        guard activeLayerIndex > 0,
              activeLayerIndex < layers.count else { return }
        
        let upperLayer = layers[activeLayerIndex]
        let lowerLayer = layers[activeLayerIndex - 1]
        
        // Merge upper layer into lower, respecting opacity
        if let upperImage = upperLayer.canvas.createImage(),
           let lowerContext = lowerLayer.canvas.context {
            lowerContext.saveGState()
            lowerContext.setAlpha(CGFloat(upperLayer.opacity))
            lowerContext.draw(upperImage, in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
            lowerContext.restoreGState()
        }
        
        layers.remove(at: activeLayerIndex)
        activeLayerIndex -= 1
        
        // Ensure index is valid
        if activeLayerIndex < 0 {
            activeLayerIndex = 0
        }
        
        saveState()
    }
    
    // MARK: - History Management
    
    /// Snapshot of drawing state for undo/redo system
    struct DrawingSnapshot {
        let layers: [DrawingLayer]
        let activeLayerIndex: Int
    }
    
    /// Save current state to history for undo/redo
    func saveState() {
        // Validate activeLayerIndex
        if activeLayerIndex < 0 || activeLayerIndex >= layers.count {
            // Fix invalid index
            if !layers.isEmpty {
                activeLayerIndex = 0
            } else {
                return
            }
        }
        
        // Create snapshot of current state by copying all layers
        let snapshot = DrawingSnapshot(
            layers: layers.map { layer in
                let newLayer = DrawingLayer(name: layer.name, width: canvasWidth, height: canvasHeight)
                newLayer.isVisible = layer.isVisible
                newLayer.opacity = layer.opacity
                if let image = layer.canvas.createImage(),
                   let context = newLayer.canvas.context {
                    context.draw(image, in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
                }
                return newLayer
            },
            activeLayerIndex: activeLayerIndex
        )
        
        // Remove any future history if we're in the middle
        if historyIndex >= 0 && historyIndex < history.count - 1 {
            history = Array(history[0...historyIndex])
        }
        
        history.append(snapshot)
        
        // Limit history size and update index
        if history.count > maxHistory {
            history.removeFirst()
            // Don't increment index when removing from front
        } else {
            historyIndex = history.count - 1
        }
        
        // Ensure index is valid
        historyIndex = min(historyIndex, history.count - 1)
        
        // Force canvas refresh
        canvasUpdateCounter += 1
    }
    
    /// Undo the last action
    /// - Returns: `true` if undo was successful, `false` if no history available
    func undo() -> Bool {
        guard historyIndex > 0, historyIndex < history.count else { return false }
        historyIndex -= 1
        guard historyIndex >= 0, historyIndex < history.count else { return false }
        restoreSnapshot(history[historyIndex])
        return true
    }
    
    /// Redo the last undone action
    /// - Returns: `true` if redo was successful, `false` if no future history available
    func redo() -> Bool {
        guard historyIndex >= 0, historyIndex < history.count - 1 else { return false }
        historyIndex += 1
        if historyIndex < history.count {
            restoreSnapshot(history[historyIndex])
            return true
        }
        return false
    }
    
    /// Check if undo is available
    func canUndo() -> Bool {
        return historyIndex > 0
    }
    
    /// Check if redo is available
    func canRedo() -> Bool {
        return historyIndex < history.count - 1
    }
    
    /// Restore a snapshot from history
    private func restoreSnapshot(_ snapshot: DrawingSnapshot) {
        layers = snapshot.layers
        
        // Validate and clamp activeLayerIndex
        if snapshot.activeLayerIndex < 0 {
            activeLayerIndex = 0
        } else if snapshot.activeLayerIndex >= snapshot.layers.count {
            activeLayerIndex = max(0, snapshot.layers.count - 1)
        } else {
            activeLayerIndex = snapshot.activeLayerIndex
        }
    }
    
    // MARK: - Canvas Size Management
    
    /// Resize the canvas and all layers
    /// - Parameters:
    ///   - width: New canvas width (1-10000)
    ///   - height: New canvas height (1-10000)
    func setCanvasSize(width: Int, height: Int) {
        // Validate dimensions
        guard width > 0, height > 0, width <= 10000, height <= 10000 else { return }
        
        canvasWidth = width
        canvasHeight = height
        
        // Resize all layers and copy existing content (top-left aligned)
        var updatedLayers: [DrawingLayer] = []
        for layer in layers {
            let newLayer = DrawingLayer(name: layer.name, width: width, height: height)
            newLayer.isVisible = layer.isVisible
            newLayer.opacity = layer.opacity
            
            // Copy existing content (preserving top-left alignment)
            if let oldImage = layer.canvas.createImage(),
               let context = newLayer.canvas.context {
                let copyWidth = min(width, layer.canvas.width)
                let copyHeight = min(height, layer.canvas.height)
                context.draw(oldImage, in: CGRect(x: 0, y: 0, width: copyWidth, height: copyHeight))
            }
            
            updatedLayers.append(newLayer)
        }
        
        layers = updatedLayers
        
        // Ensure activeLayerIndex is valid
        if activeLayerIndex >= layers.count {
            activeLayerIndex = max(0, layers.count - 1)
        }
        
        saveState()
    }
}

/// Text case transformation options for stamp text
enum TextCase {
    case upper
    case lower
}
