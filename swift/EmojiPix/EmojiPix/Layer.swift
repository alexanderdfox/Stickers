//
//  Layer.swift
//  EmojiPix
//
//  Defines the layer system for the drawing canvas.
//  Layers contain individual drawing canvases that can be composited together.
//  Each layer has its own canvas, visibility, and opacity properties.
//

import SwiftUI
import CoreGraphics
import Combine

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - DrawingLayer

/// Represents a single drawing layer in the canvas
/// Each layer has its own canvas, name, visibility, and opacity
class DrawingLayer: Identifiable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var isVisible: Bool
    @Published var opacity: Double
    let canvas: Canvas
    
    /// Initialize a new drawing layer
    /// - Parameters:
    ///   - name: Display name of the layer
    ///   - width: Canvas width in pixels
    ///   - height: Canvas height in pixels
    init(name: String, width: Int, height: Int) {
        self.id = UUID()
        self.name = name
        self.isVisible = true
        self.opacity = 1.0
        self.canvas = Canvas(width: width, height: height)
    }
    
    /// Render this layer to a SwiftUI GraphicsContext
    /// - Parameter context: The graphics context to render to
    func render(context: inout GraphicsContext) {
        guard isVisible else { return }
        
        context.opacity = opacity
        
        // Render canvas content to context
        if let cgImage = canvas.createImage() {
            let image = Image(cgImage, scale: 1.0, label: Text("Layer"))
            let size = CGSize(width: cgImage.width, height: cgImage.height)
            context.draw(image, in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Canvas

/// Core Graphics canvas for drawing operations
/// Provides a CGContext for drawing with flipped coordinate system (top-left origin)
class Canvas {
    private var cgContext: CGContext?
    let width: Int
    let height: Int
    
    /// Initialize a new canvas
    /// - Parameters:
    ///   - width: Canvas width in pixels (1-10000)
    ///   - height: Canvas height in pixels (1-10000)
    init(width: Int, height: Int) {
        // Clamp dimensions to valid range
        self.width = max(1, min(10000, width))
        self.height = max(1, min(10000, height))
        createContext()
    }
    
    /// Create the Core Graphics context with flipped coordinate system
    private func createContext() {
        // Validate dimensions
        guard width > 0, height > 0, width <= 10000, height <= 10000 else {
            return
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return
        }
        
        // Flip the coordinate system so (0,0) is at top-left like SwiftUI
        // Core Graphics uses bottom-left origin by default
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        cgContext = context
    }
    
    /// Get the Core Graphics context for drawing
    var context: CGContext? {
        return cgContext
    }
    
    /// Clear the canvas with a specified color
    /// - Parameter color: The color to fill the canvas with (default: white)
    func clear(color: Color = .white) {
        guard let context = cgContext else { return }
        
        #if canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        context.setFillColor(cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        #elseif canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        context.setFillColor(cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        #endif
    }
    
    /// Create a CGImage from the canvas content
    /// - Returns: A CGImage representation of the canvas, or nil if context is invalid
    func createImage() -> CGImage? {
        return cgContext?.makeImage()
    }
    
    /// Create a copy of this canvas with all its content
    /// - Returns: A new Canvas instance with copied content
    func copy() -> Canvas {
        let newCanvas = Canvas(width: width, height: height)
        if let image = createImage(),
           let newContext = newCanvas.context {
            newContext.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return newCanvas
    }
}

// MARK: - Color Extensions

/// Extension to convert SwiftUI Color to CGColor for platform-specific implementations
#if canImport(AppKit)
extension Color {
    /// Convert SwiftUI Color to CGColor (macOS)
    var cgColor: CGColor? {
        return NSColor(self).cgColor
    }
}
#elseif canImport(UIKit)
extension Color {
    /// Convert SwiftUI Color to CGColor (iOS)
    var cgColor: CGColor? {
        return UIColor(self).cgColor
    }
}
#endif
