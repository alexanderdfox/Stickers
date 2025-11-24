//
//  CanvasView.swift
//  Stickers
//
//  Main canvas view that handles drawing interactions and rendering.
//  Manages touch/pointer events, converts coordinates, and performs drawing operations
//  on layers using Core Graphics. Supports all drawing tools and patterns.
//

import SwiftUI
import CoreGraphics

#if canImport(AppKit)
import AppKit
#endif

// MARK: - CanvasView

/// Main drawing canvas view
/// Handles user input, coordinate conversion, and drawing operations
struct CanvasView: View {
    @ObservedObject var state: DrawingState
    #if os(iOS)
    @Binding var importedImage: UIImage?
    @Binding var importedImagePosition: CGPoint
    @Binding var isDraggingImage: Bool
    #elseif os(macOS)
    @Binding var importedImage: NSImage?
    @Binding var importedImagePosition: CGPoint
    @Binding var isDraggingImage: Bool
    #endif
    let onPlaceImage: () -> Void
    
    @State private var lastPoint: CGPoint?
    @State private var isDrawing: Bool = false
    @State private var startPoint: CGPoint?
    @State private var rainbowHueOffset: Double = 0
    @State private var enableSnapping: Bool = false
    @State private var gridSize: CGFloat = 10
    
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
            let geometrySize = geometryProxy.size
            
            ZStack {
                SwiftUI.Canvas { context, size in
                    // Render all visible layers
                    // Use canvasUpdateCounter to force refresh on every change
                    let _ = state.canvasUpdateCounter
                    
                    // Optimize: Only render visible layers
                    let visibleLayers = state.layers.filter { $0.isVisible }
                    for layer in visibleLayers {
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
                .drawingGroup() // Optimize rendering performance
                .frame(width: canvasSize.width, height: canvasSize.height)
                .background(canvasBackground)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(canvasStroke, lineWidth: 0.5)
                )
                
                // Show imported image preview if available
                #if os(iOS)
                if let image = importedImage, let cgImage = image.cgImage {
                    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    // Guard against division by zero
                    if imageSize.width > 0, imageSize.height > 0 {
                        let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height)
                        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: scaledSize.width, height: scaledSize.height)
                            .position(
                                x: importedImagePosition.x + scaledSize.width / 2,
                                y: importedImagePosition.y + scaledSize.height / 2
                            )
                            .opacity(0.8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDraggingImage = true
                                        // Convert gesture location to canvas coordinates
                                        let canvasPoint = convertPoint(value.location, in: geometrySize)
                                        importedImagePosition = CGPoint(
                                            x: max(0, min(canvasSize.width - scaledSize.width, canvasPoint.x - scaledSize.width / 2)),
                                            y: max(0, min(canvasSize.height - scaledSize.height, canvasPoint.y - scaledSize.height / 2))
                                        )
                                    }
                                    .onEnded { _ in
                                        isDraggingImage = false
                                    }
                            )
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded {
                                        onPlaceImage()
                                    }
                            )
                    }
                }
                #elseif os(macOS)
                if let image = importedImage, let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    // Guard against division by zero
                    if imageSize.width > 0, imageSize.height > 0 {
                        let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height)
                        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                        
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: scaledSize.width, height: scaledSize.height)
                            .position(
                                x: importedImagePosition.x + scaledSize.width / 2,
                                y: importedImagePosition.y + scaledSize.height / 2
                            )
                            .opacity(0.8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDraggingImage = true
                                        // Convert gesture location to canvas coordinates
                                        let canvasPoint = convertPoint(value.location, in: geometrySize)
                                        importedImagePosition = CGPoint(
                                            x: max(0, min(canvasSize.width - scaledSize.width, canvasPoint.x - scaledSize.width / 2)),
                                            y: max(0, min(canvasSize.height - scaledSize.height, canvasPoint.y - scaledSize.height / 2))
                                        )
                                    }
                                    .onEnded { _ in
                                        isDraggingImage = false
                                    }
                            )
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded {
                                        onPlaceImage()
                                    }
                            )
                    }
                }
                #endif
            }
            .gesture(
                // Only handle drawing gestures if not dragging imported image
                isDraggingImage ? nil : DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDraw(at: value.location, in: geometrySize)
                    }
                    .onEnded { value in
                        let dx = value.location.x - value.startLocation.x
                        let dy = value.location.y - value.startLocation.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance < 2 {
                            handleTap(at: value.location, in: geometrySize)
                        } else {
                            finishDrawing()
                        }
                    }
            )
        }
        .frame(width: CGFloat(state.canvasWidth), height: CGFloat(state.canvasHeight))
        .scaleEffect(state.canvasZoom)
        .animation(.easeInOut(duration: 0.2), value: state.canvasZoom)
        // Performance optimization: Use drawingGroup for better rendering
        // Removed redundant drawingGroup() here
    }
    
    private func snapPoint(_ point: CGPoint) -> CGPoint {
        guard enableSnapping, gridSize > 0 else { return point }
        let x = (point.x / gridSize).rounded() * gridSize
        let y = (point.y / gridSize).rounded() * gridSize
        return CGPoint(x: x, y: y)
    }
    
    private func snapLineEndpoints(start: CGPoint, end: CGPoint) -> (CGPoint, CGPoint) {
        guard enableSnapping else { return (start, end) }
        // Snap to grid first
        let s = snapPoint(start)
        var e = snapPoint(end)
        // Angle snapping to 0, 45, 90, 135, etc.
        let dx = e.x - s.x
        let dy = e.y - s.y
        let angle = atan2(dy, dx)
        let step = CGFloat.pi / 4 // 45 degrees
        let snappedAngle = (angle / step).rounded() * step
        let length = max(0.0, hypot(dx, dy))
        e = CGPoint(x: s.x + cos(snappedAngle) * length, y: s.y + sin(snappedAngle) * length)
        return (s, e)
    }
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        // Validate size and location
        guard size.width > 0, size.height > 0,
              location.x.isFinite, location.y.isFinite,
              let layer = state.activeLayer else { return }
        
        let point = convertPoint(location, in: size)
        
        // Validate converted point
        guard point.x.isFinite, point.y.isFinite else { return }
        
        switch state.currentTool {
        case .stamp:
            drawStamp(at: point, on: layer)
            AppPreferences.shared.playSound(.stamp)
            state.saveState()
        case .fill:
            fillAt(point: point, on: layer)
            AppPreferences.shared.playSound(.fill)
            state.saveState()
        default:
            // Clear selection if clicking outside with other tools
            if state.hasSelection {
                state.clearSelection()
            }
            break
        }
    }
    
    private func handleDraw(at location: CGPoint, in size: CGSize) {
        // Validate size and location
        guard size.width > 0, size.height > 0,
              location.x.isFinite, location.y.isFinite,
              let layer = state.activeLayer else { return }
        
        let point = convertPoint(location, in: size)
        
        // Validate converted point
        guard point.x.isFinite, point.y.isFinite else { return }
        
        if !isDrawing {
            startPoint = point
            lastPoint = point
            isDrawing = true
        }
        
        switch state.currentTool {
        case .pencil:
            if let last = lastPoint, last.x.isFinite, last.y.isFinite {
                let shouldUpdate = abs(point.x - last.x) > 1 || abs(point.y - last.y) > 1
                drawPath(from: last, to: point, on: layer)
                if shouldUpdate {
                    AppPreferences.shared.playSound(.draw)
                    state.canvasUpdateCounter += 1
                }
                lastPoint = point
            } else {
                lastPoint = point
            }
        case .spray:
            if let last = lastPoint, last.x.isFinite, last.y.isFinite {
                let shouldUpdate = abs(point.x - last.x) > 1 || abs(point.y - last.y) > 1
                drawPath(from: last, to: point, on: layer)
                if shouldUpdate {
                    AppPreferences.shared.playSound(.spray)
                    state.canvasUpdateCounter += 1
                }
                lastPoint = point
            } else {
                lastPoint = point
            }
        case .eraser:
            if let last = lastPoint, last.x.isFinite, last.y.isFinite {
                let shouldUpdate = abs(point.x - last.x) > 1 || abs(point.y - last.y) > 1
                drawPath(from: last, to: point, on: layer)
                if shouldUpdate {
                    AppPreferences.shared.playSound(.eraser)
                    state.canvasUpdateCounter += 1
                }
                lastPoint = point
            } else {
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
        
        // Apply snapping if enabled for shape tools
        var s = start
        var e = end
        if enableSnapping {
            let se = snapLineEndpoints(start: start, end: end)
            s = se.0
            e = se.1
        }
        
        switch state.currentTool {
        case .line:
            drawLine(from: s, to: e, on: layer)
            AppPreferences.shared.playSound(.shape)
        case .circle:
            drawCircle(from: s, to: e, on: layer)
            AppPreferences.shared.playSound(.shape)
        case .square:
            drawRectangle(from: s, to: e, on: layer)
            AppPreferences.shared.playSound(.shape)
        case .triangle:
            drawTriangle(from: s, to: e, on: layer)
            AppPreferences.shared.playSound(.shape)
        case .star:
            drawStar(from: s, to: e, on: layer)
            AppPreferences.shared.playSound(.shape)
        case .arc:
            drawArc(from: s, to: e, on: layer)
            AppPreferences.shared.playSound(.shape)
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
        // Guard against division by zero and invalid sizes
        guard size.width >= 1, size.height >= 1,
              !point.x.isInfinite, !point.y.isInfinite,
              !point.x.isNaN, !point.y.isNaN else {
            return .zero
        }
        
        let scaleX = CGFloat(state.canvasWidth) / size.width
        let scaleY = CGFloat(state.canvasHeight) / size.height
        
        var convertedX = point.x * scaleX
        var convertedY = point.y * scaleY
        
        // Clamp to valid canvas bounds
        convertedX = max(0, min(convertedX, CGFloat(state.canvasWidth)))
        convertedY = max(0, min(convertedY, CGFloat(state.canvasHeight)))
        
        return CGPoint(x: convertedX, y: convertedY)
    }
    
    // Drawing functions
    private func drawPath(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else { return }
        
        context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        if state.currentTool == .eraser {
            // Use destinationOut blend mode for proper erasing
            // This removes the destination pixels where the path is drawn
            context.setBlendMode(.destinationOut)
            // Set a fully opaque color - the blend mode will remove pixels regardless of color
            // We use white with full alpha so the blend mode works correctly
            context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            // Make sure the line width is appropriate for erasing
            context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
        } else if state.currentTool == .spray {
            // Spray tool uses a special spray effect
            context.setBlendMode(.normal)
            let color = state.rainbowMode ? getRainbowColor() : state.currentColor
            if let cgColor = color.cgColor {
                context.setStrokeColor(cgColor)
            }
            drawSprayEffect(from: start, to: end, on: layer)
            return // Early return since spray handles its own drawing
        } else {
            // Normal drawing tools
            context.setBlendMode(.normal)
            let color = state.rainbowMode ? getRainbowColor() : state.currentColor
            if let cgColor = color.cgColor {
                context.setStrokeColor(cgColor)
            }
        }
        
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        
        if state.sparkleMode && state.currentTool != .eraser {
            addSparkles(at: end, on: layer)
        }
        
        // Note: Update counter is handled in handleDraw for better performance
    }
    
    // Spray effect drawing
    private func drawSprayEffect(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        guard let cgColor = color.cgColor else { return }
        
        let brushSize = CGFloat(state.brushSize)
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        let steps = max(1, Int(distance / (brushSize * 0.5)))
        
        context.setBlendMode(.normal)
        context.setFillColor(cgColor)
        
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t
            
            // Draw multiple random dots for spray effect
            let dotCount = Int(brushSize / 2)
            for _ in 0..<dotCount {
                let offsetX = CGFloat.random(in: -brushSize...brushSize)
                let offsetY = CGFloat.random(in: -brushSize...brushSize)
                let dotSize = CGFloat.random(in: 1...brushSize * 0.3)
                
                let dotRect = CGRect(
                    x: x + offsetX - dotSize/2,
                    y: y + offsetY - dotSize/2,
                    width: dotSize,
                    height: dotSize
                )
                context.fillEllipse(in: dotRect)
            }
        }
    }
    
    private func drawLine(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else { return }
        
        context.setBlendMode(.normal)
        context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
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
        
        // Force canvas update
        state.canvasUpdateCounter += 1
    }
    
    private func drawCircle(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else { return }
        
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        // Skip if rect is too small
        guard rect.width > 0.5 || rect.height > 0.5 else { return }
        
        context.setBlendMode(.normal)
        context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
        
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
        
        // Force canvas update
        state.canvasUpdateCounter += 1
    }
    
    private func drawRectangle(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else { return }
        
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        // Skip if rect is too small
        guard rect.width > 0.5 || rect.height > 0.5 else { return }
        
        context.setBlendMode(.normal)
        context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
        
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
        
        // Force canvas update
        state.canvasUpdateCounter += 1
    }
    
    private func drawTriangle(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else { return }
        
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)
        
        // Skip if too small
        guard width > 0.5 || height > 0.5 else { return }
        
        let centerX = (start.x + end.x) / 2
        let topY = min(start.y, end.y)
        let bottomY = max(start.y, end.y)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX - width/2, y: bottomY))
        path.addLine(to: CGPoint(x: centerX + width/2, y: bottomY))
        path.closeSubpath()
        
        context.setBlendMode(.normal)
        context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
        
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
        
        // Force canvas update
        state.canvasUpdateCounter += 1
    }
    
    private func drawStar(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else { return }
        
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)
        
        // Skip if too small
        guard width > 1 || height > 1 else { return }
        
        let centerX = (start.x + end.x) / 2
        let centerY = (start.y + end.y) / 2
        let radius = max(1, min(width, height) / 2)
        
        let path = createStarPath(center: CGPoint(x: centerX, y: centerY), radius: radius, points: 5)
        
        context.setBlendMode(.normal)
        context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
        
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
        
        // Force canvas update
        state.canvasUpdateCounter += 1
    }
    
    private func drawArc(from start: CGPoint, to end: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else { return }
        
        let centerX = (start.x + end.x) / 2
        let centerY = (start.y + end.y) / 2
        let radius = max(1, sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2)) / 2)
        
        let path = CGMutablePath()
        let startAngle = atan2(start.y - centerY, start.x - centerX)
        let endAngle = startAngle + (state.arcSweepAngle * .pi / 180)
        
        path.addArc(center: CGPoint(x: centerX, y: centerY),
                   radius: radius,
                   startAngle: startAngle,
                   endAngle: endAngle,
                   clockwise: false)
        
        context.setBlendMode(.normal)
        let color = state.rainbowMode ? getRainbowColor() : state.currentColor
        if let cgColor = color.cgColor {
            context.setStrokeColor(cgColor)
        }
        context.setLineWidth(max(0.5, CGFloat(state.brushSize)))
        context.addPath(path)
        context.strokePath()
        
        // Force canvas update
        state.canvasUpdateCounter += 1
    }
    
    private func createStarPath(center: CGPoint, radius: CGFloat, points: Int) -> CGPath {
        let path = CGMutablePath()
        // Guard against division by zero
        guard points > 0 else {
            // Return a simple circle if points is invalid
            return CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2), transform: nil)
        }
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
        
        // Validate point and emoji
        guard point.x.isFinite, point.y.isFinite,
              !state.selectedEmoji.isEmpty else { return }
        
        // Draw emoji as text
        let fontSize = max(8, CGFloat(state.brushSize * 4))
        
        #if canImport(AppKit)
        // Use selected font or system font
        let font: NSFont
        if !state.selectedFont.isEmpty,
           let selectedFont = NSFont(name: state.selectedFont, size: fontSize) {
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
        
        // The context is already flipped, so we don't need to flip again
        // Use flipped: false to avoid double-flipping
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        emojiString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
        NSGraphicsContext.restoreGraphicsState()
        context.restoreGState()
        #elseif canImport(UIKit)
        // Use selected font or system font
        let font: UIFont
        if !state.selectedFont.isEmpty,
           let selectedFont = UIFont(name: state.selectedFont, size: fontSize) {
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
        
        // The context is already flipped, so we can draw directly
        // UIGraphicsPushContext works correctly with the flipped context
        UIGraphicsPushContext(context)
        emojiString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
        UIGraphicsPopContext()
        context.restoreGState()
        #endif
        
        // Force canvas update
        state.canvasUpdateCounter += 1
    }
    
    private func fillAt(point: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context,
              let cgImage = layer.canvas.createImage() else { return }
        
        // Validate point
        let x = Int(point.x)
        let y = Int(point.y)
        guard x >= 0, y >= 0, x < state.canvasWidth, y < state.canvasHeight else { return }
        
        // Get pixel data from the image
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let pixelData = calloc(height * width, bytesPerPixel),
              let context2 = CGContext(
                  data: pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: bitsPerComponent,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return
        }
        
        // Draw current image to get pixel data
        // The cgImage from a flipped context is in normal (bottom-left) coordinates
        // We need to flip it when drawing to our normal-coordinate context
        context2.saveGState()
        context2.translateBy(x: 0, y: CGFloat(height))
        context2.scaleBy(x: 1.0, y: -1.0)
        context2.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        context2.restoreGState()
        
        // The point.y is in top-left coordinates (from SwiftUI), but our pixel data
        // is now in normal (bottom-left) coordinates after the flip above
        // So we need to convert: y in top-left -> (height - 1 - y) in bottom-left
        let flippedY = height - 1 - y
        
        // Get the target color at the clicked point
        let pixelIndex = (flippedY * width + x) * bytesPerPixel
        let totalPixels = height * width * bytesPerPixel
        // Bounds check
        guard pixelIndex >= 0, pixelIndex + 3 < totalPixels else {
            free(pixelData)
            return
        }
        let pixelPtr = pixelData.assumingMemoryBound(to: UInt8.self)
        let targetR = pixelPtr[pixelIndex]
        let targetG = pixelPtr[pixelIndex + 1]
        let targetB = pixelPtr[pixelIndex + 2]
        let targetA = pixelPtr[pixelIndex + 3]
        
        // Flood fill to find the region to fill
        // Convert initial point from flipped coordinates to normal coordinates
        let normalY = height - 1 - y
        var queue: [(Int, Int)] = [(x, normalY)]
        var visited = Set<String>()
        var minX = x, maxX = x, minY = normalY, maxY = normalY
        var fillRegion: [(Int, Int)] = []
        
        while !queue.isEmpty {
            let (cx, cy) = queue.removeFirst()
            let key = "\(cx),\(cy)"
            
            if visited.contains(key) { continue }
            if cx < 0 || cx >= width || cy < 0 || cy >= height { continue }
            
            let idx = (cy * width + cx) * bytesPerPixel
            // Bounds check
            guard idx >= 0, idx + 3 < totalPixels else { continue }
            let r = pixelPtr[idx]
            let g = pixelPtr[idx + 1]
            let b = pixelPtr[idx + 2]
            let a = pixelPtr[idx + 3]
            
            // Check if this pixel matches the target color
            if r != targetR || g != targetG || b != targetB || a != targetA {
                continue
            }
            
            visited.insert(key)
            fillRegion.append((cx, cy))
            
            // Update bounding box
            minX = min(minX, cx)
            maxX = max(maxX, cx)
            minY = min(minY, cy)
            maxY = max(maxY, cy)
            
            // Add neighbors to queue
            queue.append((cx + 1, cy))
            queue.append((cx - 1, cy))
            queue.append((cx, cy + 1))
            queue.append((cx, cy - 1))
        }
        
        // If no region found, return
        guard !fillRegion.isEmpty else {
            free(pixelData)
            return
        }
        
        // Perform fill operation - all pixel manipulation is in normal coordinates
        // The fillRegion coordinates are already in normal (non-flipped) space
        if state.fillPattern == .solid {
            let fillColor = state.rainbowMode ? getRainbowColor() : state.currentColor
            guard let fillCGColor = fillColor.cgColor,
                  let components = fillCGColor.components else {
                free(pixelData)
                return
            }
            let fillR = UInt8(components[0] * 255)
            let fillG = UInt8(components.count > 1 ? components[1] * 255 : components[0] * 255)
            let fillB = UInt8(components.count > 2 ? components[2] * 255 : components[0] * 255)
            let fillA = UInt8(components.count > 3 ? components[3] * 255 : 255)
            
            // Check if already filled with the same color
            if targetR == fillR && targetG == fillG && targetB == fillB && targetA == fillA {
                free(pixelData)
                return
            }
            
            // Fill all pixels in the region (coordinates are in normal space)
            for (px, py) in fillRegion {
                let idx = (py * width + px) * bytesPerPixel
                guard idx >= 0, idx + 3 < totalPixels else { continue }
                pixelPtr[idx] = fillR
                pixelPtr[idx + 1] = fillG
                pixelPtr[idx + 2] = fillB
                pixelPtr[idx + 3] = fillA
            }
        } else if state.fillPattern == .transparent {
            // Transparent fill - clear the region
            for (px, py) in fillRegion {
                let idx = (py * width + px) * bytesPerPixel
                guard idx >= 0, idx + 3 < totalPixels else { continue }
                pixelPtr[idx] = 0
                pixelPtr[idx + 1] = 0
                pixelPtr[idx + 2] = 0
                pixelPtr[idx + 3] = 0
            }
        } else {
            // Pattern fill - create pattern in bounding box, then apply to region
            let bounds = CGRect(
                x: CGFloat(minX),
                y: CGFloat(minY),
                width: CGFloat(maxX - minX + 1),
                height: CGFloat(maxY - minY + 1)
            )
            let patternWidth = Int(bounds.width)
            let patternHeight = Int(bounds.height)
            guard patternWidth > 0, patternHeight > 0,
                  let patternData = calloc(patternHeight * patternWidth, bytesPerPixel),
                  let patternContext = CGContext(
                      data: patternData,
                      width: patternWidth,
                      height: patternHeight,
                      bitsPerComponent: bitsPerComponent,
                      bytesPerRow: bytesPerPixel * patternWidth,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                free(pixelData)
                return
            }
            
            // Flip pattern context to match the coordinate system we're working in
            // Since we're working in normal coordinates, we need to flip the pattern context
            patternContext.translateBy(x: 0, y: CGFloat(patternHeight))
            patternContext.scaleBy(x: 1.0, y: -1.0)
            
            // Fill background if needed
            if let bgColor = state.secondaryColor.cgColor {
                patternContext.setFillColor(bgColor)
                patternContext.fill(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
            }
            
            // Draw the pattern
            let patternRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            switch state.fillPattern {
            case .horizontal:
                drawHorizontalLinesPattern(in: patternRect, using: patternContext)
            case .vertical:
                drawVerticalLinesPattern(in: patternRect, using: patternContext)
            case .diagonal:
                drawDiagonalLinesPattern(in: patternRect, using: patternContext)
            case .checkerboard:
                drawCheckerboardPattern(in: patternRect, using: patternContext)
            case .dots:
                drawDotsPattern(in: patternRect, using: patternContext)
            default:
                break
            }
            
            // Get pattern pixel data
            let patternPtr = patternData.assumingMemoryBound(to: UInt8.self)
            let patternTotalPixels = patternHeight * patternWidth * bytesPerPixel
            
            // Apply pattern pixels to the fill region
            // Both pattern and fillRegion are in normal coordinates
            for (px, py) in fillRegion {
                // Calculate position relative to pattern bounds
                let relX = px - minX
                let relY = py - minY
                
                guard relX >= 0, relX < patternWidth, relY >= 0, relY < patternHeight else {
                    continue
                }
                
                // Get pattern pixel (pattern context is flipped, so adjust Y)
                let patternY = patternHeight - 1 - relY
                let patternIdx = (patternY * patternWidth + relX) * bytesPerPixel
                
                // Get main image pixel index (in normal coordinates)
                let mainIdx = (py * width + px) * bytesPerPixel
                
                // Bounds check for both arrays
                guard patternIdx >= 0, patternIdx + 3 < patternTotalPixels,
                      mainIdx >= 0, mainIdx + 3 < totalPixels else {
                    continue
                }
                
                // Copy pattern pixel to main image
                pixelPtr[mainIdx] = patternPtr[patternIdx]
                pixelPtr[mainIdx + 1] = patternPtr[patternIdx + 1]
                pixelPtr[mainIdx + 2] = patternPtr[patternIdx + 2]
                pixelPtr[mainIdx + 3] = patternPtr[patternIdx + 3]
            }
            
            free(patternData)
        }
        
        // Create new image from modified pixel data
        // The image is in normal coordinates, which is correct
        guard let newCGImage = context2.makeImage() else {
            free(pixelData)
            return
        }
        
        // Draw the new image back to the flipped canvas context
        // The context will automatically handle the coordinate conversion
        // We must do this on the main thread since context is not thread-safe
        // Capture necessary values to avoid retaining layer
        let canvasWidth = self.state.canvasWidth
        let canvasHeight = self.state.canvasHeight
        let imageWidth = width
        let imageHeight = height
        
        DispatchQueue.main.async { [weak layer] in
            guard let layer = layer,
                  let canvasContext = layer.canvas.context else {
                free(pixelData)
                return
            }

            // Clear and redraw with filled image
            // The canvas context is flipped (top-left origin), but newCGImage is in normal coordinates
            // We need to flip it when drawing to match the flipped context
            canvasContext.clear(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
            canvasContext.saveGState()
            canvasContext.translateBy(x: 0, y: CGFloat(imageHeight))
            canvasContext.scaleBy(x: 1.0, y: -1.0)
            canvasContext.draw(newCGImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
            canvasContext.restoreGState()

            // Publish state changes on the main actor
            Task { @MainActor in
                state.canvasUpdateCounter += 1
                state.saveState()
            }

            free(pixelData)
        }
    }
    
    private func addSparkles(at point: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Validate point
        guard point.x.isFinite, point.y.isFinite,
              point.x >= 0, point.y >= 0,
              point.x <= CGFloat(state.canvasWidth),
              point.y <= CGFloat(state.canvasHeight) else { return }
        
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
            var sparklePoint = CGPoint(x: point.x + offsetX, y: point.y + offsetY)
            
            // Clamp sparkle point to canvas bounds
            sparklePoint.x = max(0, min(sparklePoint.x, CGFloat(state.canvasWidth)))
            sparklePoint.y = max(0, min(sparklePoint.y, CGFloat(state.canvasHeight)))
            
            context.fillEllipse(in: CGRect(x: sparklePoint.x - 1, y: sparklePoint.y - 1, width: 2, height: 2))
        }
    }
    
    private func getRainbowColor() -> Color {
        // Use a more stable rainbow calculation
        rainbowHueOffset += 0.01
        if rainbowHueOffset >= 1.0 {
            rainbowHueOffset = 0
        }
        let hue = rainbowHueOffset
        return Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }
    
    // Fill pattern implementation
    private func fillShape(with pattern: FillPattern, in rect: CGRect, using context: CGContext, completion: @escaping (CGPath) -> Void) {
        // Validate rect
        guard rect.width > 0, rect.height > 0,
              rect.width.isFinite, rect.height.isFinite,
              rect.origin.x.isFinite, rect.origin.y.isFinite else {
            return
        }
        
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
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else {
            state.hasSelection = false
            return
        }
        
        state.selectionBounds = CGRect(
            x: max(0, min(start.x, end.x)),
            y: max(0, min(start.y, end.y)),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        // Clamp to canvas bounds
        state.selectionBounds.size.width = min(state.selectionBounds.width, CGFloat(state.canvasWidth) - state.selectionBounds.origin.x)
        state.selectionBounds.size.height = min(state.selectionBounds.height, CGFloat(state.canvasHeight) - state.selectionBounds.origin.y)
        
        state.hasSelection = state.selectionBounds.width > 5 && state.selectionBounds.height > 5
    }
    
    private func drawSelection(context: inout GraphicsContext, bounds: CGRect) {
        let path = Path(roundedRect: bounds, cornerRadius: 0)
        context.stroke(path, with: .color(.blue), lineWidth: 2)
    }
    
    private func drawShapePreview(context: inout GraphicsContext, start: CGPoint, end: CGPoint, in size: CGSize) {
        // Validate coordinates
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite,
              size.width > 0, size.height > 0 else { return }
        
        let startPoint = convertPoint(start, in: size)
        let endPoint = convertPoint(end, in: size)
        
        // Validate converted points
        guard startPoint.x.isFinite, startPoint.y.isFinite,
              endPoint.x.isFinite, endPoint.y.isFinite else { return }
        
        let snapped: (CGPoint, CGPoint)
        if enableSnapping {
            snapped = snapLineEndpoints(start: startPoint, end: endPoint)
        } else {
            snapped = (startPoint, endPoint)
        }
        let sp = snapped.0
        let ep = snapped.1
        
        switch state.currentTool {
        case .line:
            context.stroke(Path { path in
                path.move(to: sp)
                path.addLine(to: ep)
            }, with: .color(state.currentColor.opacity(0.5)), lineWidth: max(1.0, CGFloat(state.brushSize)))
        default:
            break
        }
    }
}

