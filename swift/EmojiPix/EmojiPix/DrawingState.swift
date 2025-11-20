//
//  DrawingState.swift
//  EmojiPix
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
