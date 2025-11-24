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
            
            ZStack(alignment: .topLeading) {
                SwiftUI.Canvas { context, size in
                    // Render all visible layers
                    // Use canvasUpdateCounter to force refresh on every change
                    let _ = state.canvasUpdateCounter
                    
                    // Draw grid if enabled (draw before layers so it appears behind)
                    if state.showGrid {
                        drawGrid(context: &context, size: size)
                    }
                    
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
                        // Only show preview for shape tools (not freehand tools)
                        if [.line, .circle, .square, .triangle, .star, .arc, .selectCircle, .selectSquare].contains(state.currentTool) {
                            drawShapePreview(context: &context, start: start, end: end, in: size)
                        }
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
                .overlay(alignment: .topLeading) {
                    // Ruler overlay (positioned around canvas)
                    if state.showRuler {
                        RulerOverlay(canvasWidth: state.canvasWidth, canvasHeight: state.canvasHeight)
                            .offset(x: -20, y: -20)
                    }
                }
                
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
                        // For shape tools, always finish drawing (even for small movements)
                        if [.line, .circle, .square, .triangle, .star, .arc, .selectCircle, .selectSquare].contains(state.currentTool) {
                            finishDrawing()
                        } else {
                            let dx = value.location.x - value.startLocation.x
                            let dy = value.location.y - value.startLocation.y
                            let distance = sqrt(dx*dx + dy*dy)
                            if distance < 2 {
                                handleTap(at: value.location, in: geometrySize)
                            } else {
                                finishDrawing()
                            }
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
        guard enableSnapping, state.showGrid, state.gridSize > 0 else { return point }
        let gridSize = state.gridSize
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
        case .line, .circle, .square, .triangle, .star, .arc, .selectCircle, .selectSquare:
            // For shape tools, just update lastPoint for preview
            // The actual drawing happens in finishDrawing()
            lastPoint = point
            state.canvasUpdateCounter += 1 // Force preview update
        default:
            break
        }
    }
    
    private func finishDrawing() {
        guard isDrawing, let layer = state.activeLayer else {
            isDrawing = false
            startPoint = nil
            lastPoint = nil
            return
        }
        
        // Ensure we have valid start and end points
        guard let start = startPoint, let end = lastPoint,
              start.x.isFinite, start.y.isFinite,
              end.x.isFinite, end.y.isFinite else {
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
        
        // Validate snapped points
        guard s.x.isFinite, s.y.isFinite, e.x.isFinite, e.y.isFinite else {
            isDrawing = false
            startPoint = nil
            lastPoint = nil
            return
        }
        
        switch state.currentTool {
        case .line:
            // Draw line even if start and end are very close
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
        // Security: Guard against division by zero, invalid sizes, and malicious inputs
        guard size.width >= 1, size.height >= 1,
              size.width.isFinite, size.height.isFinite,
              !point.x.isInfinite, !point.y.isInfinite,
              !point.x.isNaN, !point.y.isNaN,
              point.x.isFinite, point.y.isFinite,
              abs(point.x) < 1_000_000, // Reasonable coordinate limit
              abs(point.y) < 1_000_000 else { // Reasonable coordinate limit
            return .zero
        }
        
        // Security: Validate canvas dimensions
        guard state.canvasWidth > 0, state.canvasHeight > 0,
              state.canvasWidth <= 10000, state.canvasHeight <= 10000 else {
            return .zero
        }
        
        let scaleX = CGFloat(state.canvasWidth) / size.width
        let scaleY = CGFloat(state.canvasHeight) / size.height
        
        // Security: Check for overflow in multiplication
        guard scaleX.isFinite, scaleY.isFinite,
              !scaleX.isInfinite, !scaleY.isInfinite,
              !scaleX.isNaN, !scaleY.isNaN else {
            return .zero
        }
        
        var convertedX = point.x * scaleX
        var convertedY = point.y * scaleY
        
        // Security: Validate converted coordinates
        guard convertedX.isFinite, convertedY.isFinite,
              !convertedX.isInfinite, !convertedY.isInfinite,
              !convertedX.isNaN, !convertedY.isNaN else {
            return .zero
        }
        
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
        
        // The context is flipped (top-left origin), so coordinates from SwiftUI can be used directly
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
        
        // The context is flipped (top-left origin), so coordinates can be used directly
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
        
        // The context is flipped (top-left origin), so coordinates can be used directly
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
        
        // The context is flipped (top-left origin), so coordinates can be used directly
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
        
        // The context is flipped (top-left origin), so coordinates can be used directly
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
        
        // The context is flipped (top-left origin), so coordinates can be used directly
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
        
        // The context is flipped (top-left origin), so coordinates can be used directly
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
        
        // The context is flipped (top-left origin), so coordinates can be used directly
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
        // The context is flipped, so we don't need to flip again
        // Use flipped: false to avoid double-flipping
        let rect = CGRect(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
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
        
        // Security: Validate dimensions to prevent integer overflow and excessive memory allocation
        guard width > 0, height > 0,
              width <= 10000, height <= 10000,
              width * height <= 100_000_000 else { // Max 100M pixels to prevent memory exhaustion
            return
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        
        // Security: Check for integer overflow in memory calculation
        var totalPixels = width * height
        guard totalPixels > 0,
              totalPixels <= 100_000_000,
              totalPixels <= Int.max / bytesPerPixel else {
            return
        }
        
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let totalBytes = totalPixels * bytesPerPixel
        
        guard let pixelData = calloc(totalPixels, bytesPerPixel),
              pixelData != nil else {
            return
        }
        
        guard let context2 = CGContext(
                  data: pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: bitsPerComponent,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            free(pixelData)
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
        // Security: Validate coordinates before calculating index
        guard x >= 0, x < width, flippedY >= 0, flippedY < height else {
            free(pixelData)
            return
        }
        
        let pixelIndex = (flippedY * width + x) * bytesPerPixel
        totalPixels = totalBytes
        // Security: Additional bounds check
        guard pixelIndex >= 0, pixelIndex + 3 < totalPixels,
              pixelIndex < totalBytes else {
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
        
        // Security: Validate initial point
        guard x >= 0, x < width, normalY >= 0, normalY < height else {
            free(pixelData)
            return
        }
        
        var queue: [(Int, Int)] = [(x, normalY)]
        var visited = Set<String>()
        var minX = x, maxX = x, minY = normalY, maxY = normalY
        var fillRegion: [(Int, Int)] = []
        
        // Security: Prevent DoS by limiting flood fill iterations and queue size
        let maxIterations = 10_000_000 // Max 10M iterations to prevent infinite loops
        let maxQueueSize = 1_000_000 // Max queue size to prevent memory exhaustion
        var iterationCount = 0
        
        while !queue.isEmpty && iterationCount < maxIterations {
            // Security: Limit queue size to prevent memory exhaustion
            guard queue.count < maxQueueSize else {
                // Queue too large, abort to prevent DoS
                free(pixelData)
                return
            }
            
            let (cx, cy) = queue.removeFirst()
            iterationCount += 1
            
            let key = "\(cx),\(cy)"
            
            if visited.contains(key) { continue }
            
            // Security: Validate coordinates before accessing
            guard cx >= 0, cx < width, cy >= 0, cy < height else { continue }
            
            let idx = (cy * width + cx) * bytesPerPixel
            // Security: Bounds check with validated totalBytes
            guard idx >= 0, idx + 3 < totalBytes,
                  idx < totalBytes else { continue }
            
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
            
            // Security: Limit fill region size to prevent memory exhaustion
            guard fillRegion.count < 10_000_000 else {
                // Region too large, abort
                free(pixelData)
                return
            }
            
            // Update bounding box
            minX = min(minX, cx)
            maxX = max(maxX, cx)
            minY = min(minY, cy)
            maxY = max(maxY, cy)
            
            // Add neighbors to queue (with bounds checking)
            if cx + 1 < width { queue.append((cx + 1, cy)) }
            if cx - 1 >= 0 { queue.append((cx - 1, cy)) }
            if cy + 1 < height { queue.append((cx, cy + 1)) }
            if cy - 1 >= 0 { queue.append((cx, cy - 1)) }
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
            // Security: Validate each pixel before writing
            for (px, py) in fillRegion {
                // Security: Validate coordinates before calculating index
                guard px >= 0, px < width, py >= 0, py < height else { continue }
                
                let idx = (py * width + px) * bytesPerPixel
                // Security: Bounds check with validated totalBytes
                guard idx >= 0, idx + 3 < totalBytes,
                      idx < totalBytes else { continue }
                
                pixelPtr[idx] = fillR
                pixelPtr[idx + 1] = fillG
                pixelPtr[idx + 2] = fillB
                pixelPtr[idx + 3] = fillA
            }
            } else if state.fillPattern == .transparent {
                // Transparent fill - clear the region
                // Security: Validate each pixel before writing
                for (px, py) in fillRegion {
                    // Security: Validate coordinates before calculating index
                    guard px >= 0, px < width, py >= 0, py < height else { continue }
                    
                    let idx = (py * width + px) * bytesPerPixel
                    // Security: Bounds check with validated totalBytes
                    guard idx >= 0, idx + 3 < totalBytes,
                          idx < totalBytes else { continue }
                    
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
                
                // Security: Validate pattern dimensions to prevent integer overflow
                guard patternWidth > 0, patternHeight > 0,
                      patternWidth <= 10000, patternHeight <= 10000,
                      patternWidth * patternHeight <= 100_000_000,
                      patternWidth * patternHeight <= Int.max / bytesPerPixel else {
                    free(pixelData)
                    return
                }
                
                let patternTotalPixels = patternWidth * patternHeight
                let patternTotalBytes = patternTotalPixels * bytesPerPixel
                
                guard let patternData = calloc(patternTotalPixels, bytesPerPixel),
                      patternData != nil else {
                    free(pixelData)
                    return
                }
                
                guard let patternContext = CGContext(
                          data: patternData,
                          width: patternWidth,
                          height: patternHeight,
                          bitsPerComponent: bitsPerComponent,
                          bytesPerRow: bytesPerPixel * patternWidth,
                          space: colorSpace,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                      ) else {
                    free(patternData)
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
                
                // Apply pattern pixels to the fill region
                // Both pattern and fillRegion are in normal coordinates
                // Security: Validate all array accesses
                for (px, py) in fillRegion {
                    // Security: Validate main image coordinates
                    guard px >= 0, px < width, py >= 0, py < height else {
                        continue
                    }
                    
                    // Calculate position relative to pattern bounds
                    let relX = px - minX
                    let relY = py - minY
                    
                    guard relX >= 0, relX < patternWidth, relY >= 0, relY < patternHeight else {
                        continue
                    }
                    
                    // Get pattern pixel (pattern context is flipped, so adjust Y)
                    let patternY = patternHeight - 1 - relY
                    guard patternY >= 0, patternY < patternHeight else { continue }
                    
                    let patternIdx = (patternY * patternWidth + relX) * bytesPerPixel
                    
                    // Get main image pixel index (in normal coordinates)
                    let mainIdx = (py * width + px) * bytesPerPixel
                    
                    // Security: Bounds check for both arrays with validated sizes
                    guard patternIdx >= 0, patternIdx + 3 < patternTotalBytes,
                          patternIdx < patternTotalBytes,
                          mainIdx >= 0, mainIdx + 3 < totalBytes,
                          mainIdx < totalBytes else {
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
            // The canvas context is flipped (top-left origin)
            // newCGImage was created from a normal-coordinate context, so it's in bottom-left coordinates
            // We need to flip it when drawing to the flipped context
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
    
    // MARK: - Grid and Ruler Drawing
    
    /// Draw grid lines on the canvas
    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        let gridSize = state.gridSize
        guard gridSize > 0 else { return }
        
        // Use a subtle color for grid lines
        #if canImport(AppKit)
        let gridColor = Color(nsColor: .separatorColor).opacity(0.3)
        #else
        let gridColor = Color(uiColor: .separator).opacity(0.3)
        #endif
        
        let strokeStyle = StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round)
        context.opacity = 0.5
        
        // Draw vertical lines
        var x: CGFloat = 0
        while x <= size.width {
            let path = Path { path in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(path, with: .color(gridColor), style: strokeStyle)
            x += gridSize
        }
        
        // Draw horizontal lines
        var y: CGFloat = 0
        while y <= size.height {
            let path = Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(gridColor), style: strokeStyle)
            y += gridSize
        }
        
        context.opacity = 1.0
    }
    
    private func addSparkles(at point: CGPoint, on layer: DrawingLayer) {
        guard let context = layer.canvas.context else { return }
        
        // Security: Validate point with comprehensive checks
        guard point.x.isFinite, point.y.isFinite,
              !point.x.isInfinite, !point.y.isInfinite,
              !point.x.isNaN, !point.y.isNaN,
              point.x >= 0, point.y >= 0,
              point.x <= CGFloat(state.canvasWidth),
              point.y <= CGFloat(state.canvasHeight),
              state.canvasWidth > 0, state.canvasHeight > 0 else { return }
        
        #if canImport(AppKit)
        let whiteColor = NSColor.white.cgColor
        context.setFillColor(whiteColor)
        #elseif canImport(UIKit)
        let whiteColor = UIColor.white.cgColor
        context.setFillColor(whiteColor)
        #endif
        
        // Security: Limit number of sparkles to prevent resource exhaustion
        let sparkleCount = min(3, 10) // Cap at reasonable limit
        for _ in 0..<sparkleCount {
            let offsetX = CGFloat.random(in: -10...10)
            let offsetY = CGFloat.random(in: -10...10)
            var sparklePoint = CGPoint(x: point.x + offsetX, y: point.y + offsetY)
            
            // Security: Validate sparkle point
            guard sparklePoint.x.isFinite, sparklePoint.y.isFinite,
                  !sparklePoint.x.isInfinite, !sparklePoint.y.isInfinite,
                  !sparklePoint.x.isNaN, !sparklePoint.y.isNaN else {
                continue
            }
            
            // Clamp sparkle point to canvas bounds
            sparklePoint.x = max(0, min(sparklePoint.x, CGFloat(state.canvasWidth)))
            sparklePoint.y = max(0, min(sparklePoint.y, CGFloat(state.canvasHeight)))
            
            // Security: Validate sparkle size
            let sparkleSize: CGFloat = 2
            guard sparklePoint.x - sparkleSize/2 >= 0,
                  sparklePoint.y - sparkleSize/2 >= 0,
                  sparklePoint.x + sparkleSize/2 <= CGFloat(state.canvasWidth),
                  sparklePoint.y + sparkleSize/2 <= CGFloat(state.canvasHeight) else {
                continue
            }
            
            context.fillEllipse(in: CGRect(x: sparklePoint.x - sparkleSize/2, y: sparklePoint.y - sparkleSize/2, width: sparkleSize, height: sparkleSize))
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
    
    // MARK: - Core Graphics Pattern Implementation
    
    /// Pattern info structure for Core Graphics pattern callbacks
    private struct PatternInfo {
        let pattern: FillPattern
        let primaryColor: CGColor
        let secondaryColor: CGColor
        let lineWidth: CGFloat
        let patternSize: CGFloat
    }
    
    /// Create a Core Graphics pattern for the specified fill pattern type
    private func createCGPattern(for pattern: FillPattern, size: CGFloat = 20) -> CGPattern? {
        let patternBounds = CGRect(x: 0, y: 0, width: size, height: size)
        let matrix = CGAffineTransform.identity
        
        // Get colors
        let primaryColor = (state.rainbowMode ? getRainbowColor() : state.currentColor).cgColor ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let secondaryColor = state.secondaryColor.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let lineWidth = CGFloat(state.brushSize) * 0.5
        
        // Create pattern info
        let info = PatternInfo(
            pattern: pattern,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            lineWidth: lineWidth,
            patternSize: size
        )
        
        // Allocate memory for pattern info
        let infoPtr = UnsafeMutablePointer<PatternInfo>.allocate(capacity: 1)
        infoPtr.initialize(to: info)
        
        // Define pattern callbacks
        var callbacks = CGPatternCallbacks(
            version: 0,
            drawPattern: { (info, context) in
                guard let patternInfo = info?.assumingMemoryBound(to: PatternInfo.self).pointee else { return }
                
                context.saveGState()
                let bounds = CGRect(x: 0, y: 0, width: patternInfo.patternSize, height: patternInfo.patternSize)
                
                // Draw pattern based on type
                switch patternInfo.pattern {
                case .solid:
                    context.setFillColor(patternInfo.primaryColor)
                    context.fill(bounds)
                case .transparent:
                    // Transparent - do nothing
                    break
                case .horizontal:
                    context.setStrokeColor(patternInfo.primaryColor)
                    context.setLineWidth(patternInfo.lineWidth)
                    context.move(to: CGPoint(x: 0, y: patternInfo.patternSize / 2))
                    context.addLine(to: CGPoint(x: patternInfo.patternSize, y: patternInfo.patternSize / 2))
                    context.strokePath()
                case .vertical:
                    context.setStrokeColor(patternInfo.primaryColor)
                    context.setLineWidth(patternInfo.lineWidth)
                    context.move(to: CGPoint(x: patternInfo.patternSize / 2, y: 0))
                    context.addLine(to: CGPoint(x: patternInfo.patternSize / 2, y: patternInfo.patternSize))
                    context.strokePath()
                case .diagonal:
                    context.setStrokeColor(patternInfo.primaryColor)
                    context.setLineWidth(patternInfo.lineWidth)
                    context.move(to: CGPoint(x: 0, y: 0))
                    context.addLine(to: CGPoint(x: patternInfo.patternSize, y: patternInfo.patternSize))
                    context.strokePath()
                case .checkerboard:
                    // Draw checkerboard - alternate squares
                    context.setFillColor(patternInfo.primaryColor)
                    let halfSize = patternInfo.patternSize / 2
                    context.fill(CGRect(x: 0, y: 0, width: halfSize, height: halfSize))
                    context.fill(CGRect(x: halfSize, y: halfSize, width: halfSize, height: halfSize))
                    if patternInfo.secondaryColor.alpha > 0 {
                        context.setFillColor(patternInfo.secondaryColor)
                        context.fill(CGRect(x: halfSize, y: 0, width: halfSize, height: halfSize))
                        context.fill(CGRect(x: 0, y: halfSize, width: halfSize, height: halfSize))
                    }
                case .dots:
                    context.setFillColor(patternInfo.primaryColor)
                    let dotSize: CGFloat = 3
                    let centerX = patternInfo.patternSize / 2
                    let centerY = patternInfo.patternSize / 2
                    context.fillEllipse(in: CGRect(
                        x: centerX - dotSize / 2,
                        y: centerY - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    ))
                }
                
                context.restoreGState()
            },
            releaseInfo: { (info) in
                guard let patternInfo = info?.assumingMemoryBound(to: PatternInfo.self) else { return }
                patternInfo.deinitialize(count: 1)
                patternInfo.deallocate()
            }
        )
        
        // Create color space and pattern
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let patternSpace = CGColorSpace(patternBaseSpace: colorSpace) else {
            infoPtr.deinitialize(count: 1)
            infoPtr.deallocate()
            return nil
        }
        
        guard let pattern = CGPattern(
            info: infoPtr,
            bounds: patternBounds,
            matrix: matrix,
            xStep: size,
            yStep: size,
            tiling: .constantSpacing,
            isColored: true,
            callbacks: &callbacks
        ) else {
            infoPtr.deinitialize(count: 1)
            infoPtr.deallocate()
            return nil
        }
        
        return pattern
    }
    
    // Fill pattern implementation using Core Graphics patterns
    private func fillShape(with pattern: FillPattern, in rect: CGRect, using context: CGContext, completion: @escaping (CGPath) -> Void) {
        // Validate rect
        guard rect.width > 0, rect.height > 0,
              rect.width.isFinite, rect.height.isFinite,
              rect.origin.x.isFinite, rect.origin.y.isFinite else {
            return
        }
        
        context.saveGState()
        
        // Create clipping path
        let path = CGPath(rect: rect, transform: nil)
        context.addPath(path)
        context.clip()
        
        // Fill with pattern or solid color
        switch pattern {
        case .solid:
            if let cgColor = state.currentColor.cgColor {
                context.setFillColor(cgColor)
                context.fill(rect)
            }
        case .transparent:
            // Transparent - do nothing
            break
        case .horizontal, .vertical, .diagonal, .checkerboard, .dots:
            // Use Core Graphics pattern
            if let cgPattern = createCGPattern(for: pattern, size: 20) {
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                guard let patternSpace = CGColorSpace(patternBaseSpace: colorSpace) else {
                    // Fallback to manual drawing
                    drawPatternManually(pattern: pattern, in: rect, using: context)
                    context.restoreGState()
                    return
                }
                
                var alpha: CGFloat = 1.0
                context.setFillColorSpace(patternSpace)
                context.setFillPattern(cgPattern, colorComponents: &alpha)
                context.fill(rect)
            } else {
                // Fallback to manual drawing if pattern creation fails
                drawPatternManually(pattern: pattern, in: rect, using: context)
            }
        }
        
        context.restoreGState()
    }
    
    /// Fallback manual pattern drawing (used if Core Graphics pattern fails)
    private func drawPatternManually(pattern: FillPattern, in rect: CGRect, using context: CGContext) {
        switch pattern {
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
        default:
            break
        }
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
        
        // Points are already in canvas coordinates, no need to convert
        let startPoint = start
        let endPoint = end
        
        // Validate points
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
        
        let previewColor = state.rainbowMode ? getRainbowColor() : state.currentColor
        let strokeStyle = StrokeStyle(lineWidth: max(1.0, CGFloat(state.brushSize)), lineCap: .round, lineJoin: .round)
        
        switch state.currentTool {
        case .line:
            context.stroke(Path { path in
                path.move(to: sp)
                path.addLine(to: ep)
            }, with: .color(previewColor.opacity(0.5)), style: strokeStyle)
        case .circle:
            let rect = CGRect(
                x: min(sp.x, ep.x),
                y: min(sp.y, ep.y),
                width: abs(ep.x - sp.x),
                height: abs(ep.y - sp.y)
            )
            context.stroke(Path(ellipseIn: rect), with: .color(previewColor.opacity(0.5)), style: strokeStyle)
        case .square:
            let rect = CGRect(
                x: min(sp.x, ep.x),
                y: min(sp.y, ep.y),
                width: abs(ep.x - sp.x),
                height: abs(ep.y - sp.y)
            )
            context.stroke(Path(rect), with: .color(previewColor.opacity(0.5)), style: strokeStyle)
        case .triangle:
            let width = abs(ep.x - sp.x)
            let height = abs(ep.y - sp.y)
            let centerX = (sp.x + ep.x) / 2
            let topY = min(sp.y, ep.y)
            let bottomY = max(sp.y, ep.y)
            
            let path = Path { path in
                path.move(to: CGPoint(x: centerX, y: topY))
                path.addLine(to: CGPoint(x: centerX - width/2, y: bottomY))
                path.addLine(to: CGPoint(x: centerX + width/2, y: bottomY))
                path.closeSubpath()
            }
            context.stroke(path, with: .color(previewColor.opacity(0.5)), style: strokeStyle)
        case .star:
            let width = abs(ep.x - sp.x)
            let height = abs(ep.y - sp.y)
            let centerX = (sp.x + ep.x) / 2
            let centerY = (sp.y + ep.y) / 2
            let radius = max(1, min(width, height) / 2)
            
            let path = createStarPath(center: CGPoint(x: centerX, y: centerY), radius: radius, points: 5)
            context.stroke(Path(path), with: .color(previewColor.opacity(0.5)), style: strokeStyle)
        case .arc:
            let centerX = (sp.x + ep.x) / 2
            let centerY = (sp.y + ep.y) / 2
            let radius = max(1, sqrt(pow(ep.x - sp.x, 2) + pow(ep.y - sp.y, 2)) / 2)
            
            let startAngle = atan2(sp.y - centerY, sp.x - centerX)
            let endAngle = startAngle + (state.arcSweepAngle * .pi / 180)
            
            // Create arc path using CGPath and convert to SwiftUI Path
            let cgPath = CGMutablePath()
            cgPath.addArc(center: CGPoint(x: centerX, y: centerY),
                         radius: radius,
                         startAngle: startAngle,
                         endAngle: endAngle,
                         clockwise: false)
            context.stroke(Path(cgPath), with: .color(previewColor.opacity(0.5)), style: strokeStyle)
        default:
            break
        }
    }
}

