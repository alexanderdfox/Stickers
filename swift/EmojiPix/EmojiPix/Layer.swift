//
//  Layer.swift
//  EmojiPix
//

import SwiftUI
import CoreGraphics
import Combine

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

class DrawingLayer: Identifiable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var isVisible: Bool
    @Published var opacity: Double
    let canvas: Canvas
    
    init(name: String, width: Int, height: Int) {
        self.id = UUID()
        self.name = name
        self.isVisible = true
        self.opacity = 1.0
        self.canvas = Canvas(width: width, height: height)
    }
    
    func render(context: inout GraphicsContext) {
        guard isVisible else { return }
        
        context.opacity = opacity
        
        // Render canvas to context
        if let cgImage = canvas.createImage() {
            let image = Image(cgImage, scale: 1.0, label: Text("Layer"))
            let size = CGSize(width: cgImage.width, height: cgImage.height)
            context.draw(image, in: CGRect(origin: .zero, size: size))
        }
    }
}

class Canvas {
    private var cgContext: CGContext?
    let width: Int
    let height: Int
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        createContext()
    }
    
    private func createContext() {
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
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        cgContext = context
    }
    
    var context: CGContext? {
        return cgContext
    }
    
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
    
    func createImage() -> CGImage? {
        return cgContext?.makeImage()
    }
    
    func copy() -> Canvas {
        let newCanvas = Canvas(width: width, height: height)
        if let image = createImage(),
           let newContext = newCanvas.context {
            newContext.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return newCanvas
    }
}

// Extension to convert SwiftUI Color to CGColor for macOS
#if canImport(AppKit)
extension Color {
    var cgColor: CGColor? {
        return NSColor(self).cgColor
    }
}
#elseif canImport(UIKit)
extension Color {
    var cgColor: CGColor? {
        return UIColor(self).cgColor
    }
}
#endif

