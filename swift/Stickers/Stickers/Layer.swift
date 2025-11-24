//
//  Layer.swift
//  Stickers
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
    @Published var opacity: Double {
        didSet {
            // Clamp opacity to valid range [0.0, 1.0]
            if opacity < 0.0 {
                opacity = 0.0
            } else if opacity > 1.0 {
                opacity = 1.0
            }
        }
    }
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
    /// Note: Opacity is automatically clamped to [0.0, 1.0] range
    func render(context: inout GraphicsContext) {
        guard isVisible, opacity > 0 else { return }
        
        // Opacity is already clamped by the property observer, but ensure it's valid
        let clampedOpacity = max(0.0, min(1.0, opacity))
        context.opacity = clampedOpacity
        
        // Render canvas content to context
        // Cache the image to avoid recreating it every frame
        if let cgImage = canvas.createImage() {
            let image = Image(cgImage, scale: 1.0, label: Text("Layer"))
            let size = CGSize(width: cgImage.width, height: cgImage.height)
            
            // The canvas context is flipped (top-left origin), so when we create a CGImage from it,
            // the CGImage is in normal (bottom-left) coordinates. SwiftUI's GraphicsContext uses
            // top-left origin, so we need to flip the image vertically when drawing.
            // Since SwiftUI GraphicsContext doesn't have saveGState/restoreGState, we manually
            // apply and reverse the transform.
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            context.draw(image, in: CGRect(origin: .zero, size: size))
            // Reverse the transform
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: -size.height)
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
    /// Note: This method can be called multiple times to recreate the context if needed
    private func createContext() {
        // Dimensions are already clamped in init, but validate again for safety
        guard width > 0, height > 0, width <= 10000, height <= 10000 else {
            cgContext = nil
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
            cgContext = nil
            return
        }
        
        // Flip the coordinate system so (0,0) is at top-left like SwiftUI
        // Core Graphics uses bottom-left origin by default
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        cgContext = context
    }
    
    /// Recreate the context if it was lost or invalid
    /// This can be called if the context becomes nil unexpectedly
    func recreateContext() {
        createContext()
    }
    
    /// Get the Core Graphics context for drawing
    var context: CGContext? {
        return cgContext
    }
    
    /// Clear the canvas with a specified color
    /// - Parameter color: The color to fill the canvas with (default: white)
    func clear(color: Color = .white) {
        // Try to recreate context if it's nil
        if cgContext == nil {
            recreateContext()
        }
        
        guard let context = cgContext else { return }
        
        #if canImport(AppKit)
        let nsColor = NSColor(color)
        context.setFillColor(nsColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        #elseif canImport(UIKit)
        let uiColor = UIColor(color)
        context.setFillColor(uiColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        #endif
    }
    
    /// Create a CGImage from the canvas content
    /// - Returns: A CGImage representation of the canvas, or nil if context is invalid
    func createImage() -> CGImage? {
        guard let context = cgContext else {
            // Try to recreate context if it's nil
            recreateContext()
            return cgContext?.makeImage()
        }
        return context.makeImage()
    }
    
    /// Create a copy of this canvas with all its content
    /// - Returns: A new Canvas instance with copied content
    /// Note: If the source canvas has no valid context, the copy will be empty
    func copy() -> Canvas {
        let newCanvas = Canvas(width: width, height: height)
        guard let image = createImage(),
              let newContext = newCanvas.context else {
            // If source has no image, return empty canvas (already initialized with white background)
            return newCanvas
        }
        // The context is flipped (top-left origin), but image is in normal (bottom-left) coordinates
        // We need to flip the image when drawing to match the flipped context
        newContext.saveGState()
        newContext.translateBy(x: 0, y: CGFloat(height))
        newContext.scaleBy(x: 1.0, y: -1.0)
        newContext.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        newContext.restoreGState()
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
