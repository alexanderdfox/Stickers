//
//  DrawingState.swift
//  EmojiPix
//

import SwiftUI
import CoreGraphics
import Combine

class DrawingState: ObservableObject {
    // Canvas
    @Published var canvasWidth: Int = 800
    @Published var canvasHeight: Int = 600
    
    // Tools
    @Published var currentTool: ToolType = .pencil
    @Published var brushSize: Double = 5
    @Published var currentColor: Color = .red
    @Published var secondaryColor: Color = .white
    @Published var fillPattern: FillPattern = .solid
    
    // Effects
    @Published var rainbowMode: Bool = false
    @Published var sparkleMode: Bool = false
    @Published var mirrorMode: Bool = false
    
    // Stamps
    @Published var selectedEmoji: String = "😀"
    @Published var stampRotation: Double = 0
    @Published var selectedFont: String = "Arial"
    @Published var textCase: TextCase = .upper
    
    // Arc
    @Published var arcSweepAngle: Double = 90
    
    // Zoom
    @Published var canvasZoom: Double = 1.0
    
    // Layers
    @Published var layers: [DrawingLayer] = []
    @Published var activeLayerIndex: Int = 0
    
    // Selection
    @Published var hasSelection: Bool = false
    @Published var selectionBounds: CGRect = .zero
    @Published var clipboard: CGImage?
    
    // History
    private var history: [DrawingSnapshot] = []
    private var historyIndex: Int = -1
    private let maxHistory = 50
    
    init() {
        initializeLayers()
    }
    
    func initializeLayers() {
        layers = []
        let background = DrawingLayer(name: "Background", width: canvasWidth, height: canvasHeight)
        background.canvas.clear(color: .white)
        layers.append(background)
        activeLayerIndex = 0
        saveState()
    }
    
    var activeLayer: DrawingLayer? {
        guard activeLayerIndex < layers.count else { return nil }
        return layers[activeLayerIndex]
    }
    
    func addLayer() {
        let newLayer = DrawingLayer(name: "Layer \(layers.count + 1)", width: canvasWidth, height: canvasHeight)
        layers.append(newLayer)
        activeLayerIndex = layers.count - 1
        saveState()
    }
    
    func deleteActiveLayer() {
        guard layers.count > 1 else { return }
        layers.remove(at: activeLayerIndex)
        if activeLayerIndex >= layers.count {
            activeLayerIndex = layers.count - 1
        }
        saveState()
    }
    
    func duplicateActiveLayer() {
        guard let layer = activeLayer else { return }
        let newLayer = DrawingLayer(name: "\(layer.name) Copy", width: canvasWidth, height: canvasHeight)
        if let image = layer.canvas.createImage(),
           let context = newLayer.canvas.context {
            context.draw(image, in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        }
        layers.insert(newLayer, at: activeLayerIndex + 1)
        activeLayerIndex += 1
        saveState()
    }
    
    func mergeDown() {
        guard activeLayerIndex > 0 else { return }
        let upperLayer = layers[activeLayerIndex]
        let lowerLayer = layers[activeLayerIndex - 1]
        
        if let upperImage = upperLayer.canvas.createImage(),
           let lowerContext = lowerLayer.canvas.context {
            lowerContext.draw(upperImage, in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        }
        
        layers.remove(at: activeLayerIndex)
        activeLayerIndex -= 1
        saveState()
    }
    
    // History management
    struct DrawingSnapshot {
        let layers: [DrawingLayer]
        let activeLayerIndex: Int
    }
    
    func saveState() {
        // Create snapshot of current state
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
        if historyIndex < history.count - 1 {
            history = Array(history[0...historyIndex])
        }
        
        history.append(snapshot)
        
        // Limit history size
        if history.count > maxHistory {
            history.removeFirst()
        } else {
            historyIndex += 1
        }
    }
    
    func undo() -> Bool {
        guard historyIndex > 0 else { return false }
        historyIndex -= 1
        restoreSnapshot(history[historyIndex])
        return true
    }
    
    func redo() -> Bool {
        guard historyIndex < history.count - 1 else { return false }
        historyIndex += 1
        restoreSnapshot(history[historyIndex])
        return true
    }
    
    func canUndo() -> Bool {
        return historyIndex > 0
    }
    
    func canRedo() -> Bool {
        return historyIndex < history.count - 1
    }
    
    private func restoreSnapshot(_ snapshot: DrawingSnapshot) {
        layers = snapshot.layers
        activeLayerIndex = snapshot.activeLayerIndex
    }
    
    func setCanvasSize(width: Int, height: Int) {
        canvasWidth = width
        canvasHeight = height
        
        // Resize all layers
        for layer in layers {
            let newLayer = DrawingLayer(name: layer.name, width: width, height: height)
            newLayer.isVisible = layer.isVisible
            newLayer.opacity = layer.opacity
            
            // Copy existing content (top-left aligned)
            if let oldImage = layer.canvas.createImage(),
               let context = newLayer.canvas.context {
                context.draw(oldImage, in: CGRect(x: 0, y: 0, width: min(width, layer.canvas.width), height: min(height, layer.canvas.height)))
            }
            
            if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                layers[index] = newLayer
            }
        }
        
        saveState()
    }
}

enum TextCase {
    case upper
    case lower
}

