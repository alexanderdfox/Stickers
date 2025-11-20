//
//  CanvasView.swift
//  EmojiPix
//

import SwiftUI
import CoreGraphics

#if canImport(AppKit)
import AppKit
#endif

struct CanvasView: View {
    @ObservedObject var state: DrawingState
    @State private var lastPoint: CGPoint?
    @State private var isDrawing: Bool = false
    @State private var startPoint: CGPoint?
    
    private var canvasBackground: Color {
        #if os(macOS)
        return Color.white
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }
    
    private var canvasStroke: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color(uiColor: .separator)
        #endif
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            let canvasSize = CGSize(width: state.canvasWidth, height: state.canvasHeight)
            
            SwiftUI.Canvas { context, size in
                // Render all visible layers
                for layer in state.layers where layer.isVisible {
                    layer.render(context: &context)
                }
                
                // Draw selection outline if active
                if state.hasSelection {
                    drawSelection(context: &context, bounds: state.selectionBounds)
                }
                
                // Draw temporary shape preview while drawing
                if isDrawing, let start = startPoint, let end = lastPoint {
                    drawShapePreview(context: &context, start: start, end: end, in: size)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .background(canvasBackground)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canvasStroke, lineWidth: 0.5)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDraw(at: value.location, in: geometryProxy.size)
                    }
                    .onEnded { value in
                        if value.translation == .zero {
                            handleTap(at: value.location, in: geometryProxy.size)
                        } else {
                            finishDrawing()
                        }
                    }
            )
        }
        .frame(width: CGFloat(state.canvasWidth), height: CGFloat(state.canvasHeight))
        .scaleEffect(state.canvasZoom)
        .animation(.easeInOut(duration: 0.2), value: state.canvasZoom)
    }
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard let layer = state.activeLayer else { return }
        let point = convertPoint(location, in: size)
        
        switch state.currentTool {
        case .stamp:
            drawStamp(at: point, on: layer)
            state.saveState()
        case .fill:
            fillAt(point: point, on: layer)
            state.saveState()
        default:
            break
        }
    }
    
    private func handleDraw(at location: CGPoint, in size: CGSize) {
        let point = convertPoint(location, in: size)
        guard let layer = state.activeLayer else { return }
        
        if !isDrawing {
            startPoint = point
            isDrawing = true
        }
        
        lastPoint = point
        
        switch state.currentTool {
        case .pencil, .eraser, .spray:
            if let last = lastPoint {
                drawPath(from: last, to: point, on: layer)
                lastPoint = point
            }
        default:
            break
        }
    }
    
    private func finishDrawing() {
        guard isDrawing, let start = startPoint, let end = lastPoint,
              let layer = state.activeLayer else {
            isDrawing = false
            startPoint = nil
            lastPoint = nil
            return
        }
        
        switch state.currentTool {
        case .line:
            drawLine(from: start, to: end, on: layer)
        case .circle:
            drawCircle(from: start, to: end, on: layer)
        case .square:
            drawRectangle(from: start, to: end, on: layer)
        case .triangle:
            drawTriangle(from: start, to: end, on: layer)
        case .star:
            drawStar(from: start, to: end, on: layer)
        case .arc:
            drawArc(from: start, to: end, on: layer)
        case .selectCircle, .selectSquare:
            updateSelection(from: start, to: end)
        default:
            break
        }
        
        state.saveState()
        isDrawing = false
        startPoint = nil
        lastPoint = nil
    }
    
    private func convertPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let scaleX = CGFloat(state.canvasWidth) / size.width
        let scaleY = CGFloat(state.canvasHeight) / size.height
        // Y coordinate is already correct since we flipped the context coordinate system
        return CGPoint(x: point.x * scaleX, y: point.y * scaleY)
    }
    
    // Drawing functions
    private func drawPath(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        context.setLineWidth(CGFloat(state.brushSize))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        if state.currentTool == .eraser {
            context.setBlendMode(.clear)
        } else {
            context.setBlendMode(.normal)
            let color = state.rainbowMode ? getRainbowColor() : state.currentColor
            if let cgColor = color.cgColor {
                context.setStrokeColor(cgColor)
            }
        }
        
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        
        if state.sparkleMode {
            addSparkles(at: end, on: layer)
        }
    }
    
    private func drawLine(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        context.setLineWidth(CGFloat(state.brushSize))
        context.setLineCap(.round)
        
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setStrokeColor(cgColor)
        }
        
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        
        if state.sparkleMode {
            addSparkles(at: end, on: layer)
        }
    }
    
    private func drawCircle(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        context.setLineWidth(CGFloat(state.brushSize))
        
        // Fill pattern
        if state.fillPattern != .transparent {
            context.saveGState()
            let path = CGPath(ellipseIn: rect, transform: nil)
            context.addPath(path)
            context.clip()
            fillShape(with: state.fillPattern, in: rect, using: context) { fillPath in
                context.addPath(fillPath)
                context.fillPath()
            }
            context.restoreGState()
        }
        
        // Stroke
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setStrokeColor(cgColor)
            context.strokeEllipse(in: rect)
        }
    }
    
    private func drawRectangle(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        context.setLineWidth(CGFloat(state.brushSize))
        
        // Fill
        if state.fillPattern != .transparent {
            context.saveGState()
            let path = CGPath(rect: rect, transform: nil)
            context.addPath(path)
            context.clip()
            fillShape(with: state.fillPattern, in: rect, using: context) { fillPath in
                context.addPath(fillPath)
                context.fillPath()
            }
            context.restoreGState()
        }
        
        // Stroke
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setStrokeColor(cgColor)
            context.stroke(rect)
        }
    }
    
    private func drawTriangle(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        let width = abs(end.x - start.x)
        let centerX = (start.x + end.x) / 2
        let topY = min(start.y, end.y)
        let bottomY = max(start.y, end.y)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX - width/2, y: bottomY))
        path.addLine(to: CGPoint(x: centerX + width/2, y: bottomY))
        path.closeSubpath()
        
        context.setLineWidth(CGFloat(state.brushSize))
        
        // Fill
        if state.fillPattern != .transparent {
            context.saveGState()
            context.addPath(path)
            context.clip()
            let bounds = path.boundingBox
            fillShape(with: state.fillPattern, in: bounds, using: context) { fillPath in
                context.addPath(fillPath)
                context.fillPath()
            }
            context.restoreGState()
        }
        
        // Stroke
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setStrokeColor(cgColor)
            context.addPath(path)
            context.strokePath()
        }
    }
    
    private func drawStar(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)
        let centerX = (start.x + end.x) / 2
        let centerY = (start.y + end.y) / 2
        let radius = min(width, height) / 2
        
        let path = createStarPath(center: CGPoint(x: centerX, y: centerY), radius: radius, points: 5)
        
        context.setLineWidth(CGFloat(state.brushSize))
        
        // Fill
        if state.fillPattern != .transparent {
            context.saveGState()
            context.addPath(path)
            context.clip()
            let bounds = path.boundingBox
            fillShape(with: state.fillPattern, in: bounds, using: context) { fillPath in
                context.addPath(fillPath)
                context.fillPath()
            }
            context.restoreGState()
        }
        
        // Stroke
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setStrokeColor(cgColor)
            context.addPath(path)
            context.strokePath()
        }
    }
    
    private func drawArc(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        let centerX = (start.x + end.x) / 2
        let centerY = (start.y + end.y) / 2
        let radius = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2)) / 2
        
        let path = CGMutablePath()
        let startAngle = atan2(start.y - centerY, start.x - centerX)
        let endAngle = startAngle + (state.arcSweepAngle * .pi / 180)
        
        path.addArc(center: CGPoint(x: centerX, y: centerY),
                   radius: radius,
                   startAngle: startAngle,
                   endAngle: endAngle,
                   clockwise: false)
        
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setStrokeColor(cgColor)
        }
        context.setLineWidth(CGFloat(state.brushSize))
        context.addPath(path)
        context.strokePath()
    }
    
    private func createStarPath(center: CGPoint, radius: CGFloat, points: Int) -> CGPath {
        let path = CGMutablePath()
        let angle = 4 * CGFloat.pi / CGFloat(points * 2)
        
        var firstPoint = true
        for i in 0..<points * 2 {
            let r = (i % 2 == 0) ? radius : radius * 0.4
            let currentAngle = CGFloat(i) * angle - CGFloat.pi / 2
            let x = center.x + r * cos(currentAngle)
            let y = center.y + r * sin(currentAngle)
            
            if firstPoint {
                path.move(to: CGPoint(x: x, y: y))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func drawStamp(at point: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Draw emoji as text
        let fontSize = CGFloat(state.brushSize * 4)
        
        #if canImport(AppKit)
        // Use selected font or system font
        let font: NSFont
        if let selectedFont = NSFont(name: state.selectedFont, size: fontSize) {
            font = selectedFont
        } else {
            font = NSFont.systemFont(ofSize: fontSize)
        }
        let nsColor = NSColor(state.currentColor)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: nsColor
        ]
        let emojiString = NSAttributedString(string: state.selectedEmoji, attributes: attributes)
        let textSize = emojiString.size()
        
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        context.rotate(by: -state.stampRotation * .pi / 180) // Negative for correct rotation direction
        context.translateBy(x: -point.x, y: -point.y)
        
        // Draw emoji using NSGraphicsContext for macOS
        let rect = CGRect(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        emojiString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
        NSGraphicsContext.restoreGraphicsState()
        context.restoreGState()
        #elseif canImport(UIKit)
        // Use selected font or system font
        let font: UIFont
        if let selectedFont = UIFont(name: state.selectedFont, size: fontSize) {
            font = selectedFont
        } else {
            font = UIFont.systemFont(ofSize: fontSize)
        }
        let uiColor = UIColor(state.currentColor)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: uiColor
        ]
        let emojiString = NSAttributedString(string: state.selectedEmoji, attributes: attributes)
        let textSize = emojiString.size()
        
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        context.rotate(by: -state.stampRotation * .pi / 180)
        context.translateBy(x: -point.x, y: -point.y)
        
        let rect = CGRect(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        UIGraphicsPushContext(context)
        emojiString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
        UIGraphicsPopContext()
        context.restoreGState()
        #endif
    }
    
    private func fillAt(point: CGPoint, on layer: DrawingLayer) {
        // Flood fill implementation would go here
        // This is a simplified version
        guard let context = layer.canvas.context else { return }
        
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setFillColor(cgColor)
            context.fill(CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20))
        }
    }
    
    private func addSparkles(at point: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        #if canImport(AppKit)
        let whiteColor = NSColor.white.cgColor
        context.setFillColor(whiteColor)
        #elseif canImport(UIKit)
        let whiteColor = UIColor.white.cgColor
        context.setFillColor(whiteColor)
        #endif
        
        for _ in 0..<3 {
            let offsetX = CGFloat.random(in: -10...10)
            let offsetY = CGFloat.random(in: -10...10)
            let sparklePoint = CGPoint(x: point.x + offsetX, y: point.y + offsetY)
            
            context.fillEllipse(in: CGRect(x: sparklePoint.x - 1, y: sparklePoint.y - 1, width: 2, height: 2))
        }
    }
    
    private func getRainbowColor() -> Color {
        let hue = (Date().timeIntervalSince1970 * 100).truncatingRemainder(dividingBy: 360) / 360
        return Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }
    
    // Fill pattern implementation
    private func fillShape(with pattern: FillPattern, in rect: CGRect, using context: CGContext, completion: @escaping (CGPath) -> Void) {
        context.saveGState()
        
        // First fill background if needed
        if let bgColor = state.secondaryColor.cgColor {
            context.setFillColor(bgColor)
            let bgPath = CGPath(rect: rect, transform: nil)
            completion(bgPath)
        }
        
        // Then draw pattern
        switch pattern {
        case .solid:
            if let cgColor = state.currentColor.cgColor {
                context.setFillColor(cgColor)
                let path = CGPath(rect: rect, transform: nil)
                completion(path)
            }
        case .transparent:
            break
        case .horizontal:
            drawHorizontalLinesPattern(in: rect, using: context)
        case .vertical:
            drawVerticalLinesPattern(in: rect, using: context)
        case .diagonal:
            drawDiagonalLinesPattern(in: rect, using: context)
        case .checkerboard:
            drawCheckerboardPattern(in: rect, using: context)
        case .dots:
            drawDotsPattern(in: rect, using: context)
        }
        
        context.restoreGState()
    }
    
    private func drawHorizontalLinesPattern(in rect: CGRect, using context: CGContext) {
        let path = CGMutablePath()
        let spacing: CGFloat = 8
        var y = rect.minY
        
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        
        if let cgColor = state.currentColor.cgColor {
            context.setStrokeColor(cgColor)
            context.setLineWidth(CGFloat(state.brushSize) * 0.5)
            context.addPath(path)
            context.strokePath()
        }
    }
    
    private func drawVerticalLinesPattern(in rect: CGRect, using context: CGContext) {
        let path = CGMutablePath()
        let spacing: CGFloat = 8
        var x = rect.minX
        
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }
        
        if let cgColor = state.currentColor.cgColor {
            context.setStrokeColor(cgColor)
            context.setLineWidth(CGFloat(state.brushSize) * 0.5)
            context.addPath(path)
            context.strokePath()
        }
    }
    
    private func drawDiagonalLinesPattern(in rect: CGRect, using context: CGContext) {
        let path = CGMutablePath()
        let spacing: CGFloat = 10
        let diagonal = sqrt(rect.width * rect.width + rect.height * rect.height)
        
        var offset: CGFloat = -diagonal
        while offset <= diagonal {
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.maxY))
            offset += spacing
        }
        
        if let cgColor = state.currentColor.cgColor {
            context.setStrokeColor(cgColor)
            context.setLineWidth(CGFloat(state.brushSize) * 0.5)
            context.addPath(path)
            context.strokePath()
        }
    }
    
    private func drawCheckerboardPattern(in rect: CGRect, using context: CGContext) {
        let squareSize: CGFloat = 16
        let path = CGMutablePath()
        
        var y = rect.minY
        var row = 0
        while y < rect.maxY {
            var x = rect.minX
            var col = 0
            while x < rect.maxX {
                if (row + col) % 2 == 0 {
                    let square = CGRect(x: x, y: y, width: min(squareSize, rect.maxX - x), height: min(squareSize, rect.maxY - y))
                    path.addRect(square)
                }
                x += squareSize
                col += 1
            }
            y += squareSize
            row += 1
        }
        
        if let cgColor = state.currentColor.cgColor {
            context.setFillColor(cgColor)
            context.addPath(path)
            context.fillPath()
        }
    }
    
    private func drawDotsPattern(in rect: CGRect, using context: CGContext) {
        let spacing: CGFloat = 12
        let dotSize: CGFloat = 3
        let path = CGMutablePath()
        
        var y = rect.minY + spacing / 2
        while y <= rect.maxY {
            var x = rect.minX + spacing / 2
            while x <= rect.maxX {
                let dot = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                path.addEllipse(in: dot)
                x += spacing
            }
            y += spacing
        }
        
        if let cgColor = state.currentColor.cgColor {
            context.setFillColor(cgColor)
            context.addPath(path)
            context.fillPath()
        }
    }
    
    private func updateSelection(from start: CGPoint, to end: CGPoint) {
        state.selectionBounds = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        state.hasSelection = state.selectionBounds.width > 5 && state.selectionBounds.height > 5
    }
    
    private func drawSelection(context: inout GraphicsContext, bounds: CGRect) {
        let path = Path(roundedRect: bounds, cornerRadius: 0)
        context.stroke(path, with: .color(.blue), lineWidth: 2)
    }
    
    private func drawShapePreview(context: inout GraphicsContext, start: CGPoint, end: CGPoint, in size: CGSize) {
        let startPoint = convertPoint(start, in: size)
        let endPoint = convertPoint(end, in: size)
        
        switch state.currentTool {
        case .line:
            context.stroke(Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }, with: .color(state.currentColor.opacity(0.5)), lineWidth: CGFloat(state.brushSize))
        default:
            break
        }
    }
}

