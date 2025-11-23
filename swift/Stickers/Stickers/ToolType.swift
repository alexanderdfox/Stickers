//
//  ToolType.swift
//  Stickers
//
//  Defines drawing tools and fill patterns available in the application.
//  Each tool has an icon, name, and optional keyboard shortcut.
//

import Foundation

/// Enumeration of all available drawing tools
enum ToolType: String, CaseIterable {
    case pencil = "pencil"
    case line = "line"
    case eraser = "eraser"
    case fill = "fill"
    case spray = "spray"
    case circle = "circle"
    case square = "square"
    case triangle = "triangle"
    case star = "star"
    case arc = "arc"
    case stamp = "stamp"
    case selectCircle = "select-circle"
    case selectSquare = "select-square"
    
    /// Emoji icon representation of the tool
    var icon: String {
        switch self {
        case .pencil: return "✏️"
        case .line: return "📏"
        case .eraser: return "🧽"
        case .fill: return "🪣"
        case .spray: return "💨"
        case .circle: return "⭕"
        case .square: return "⬜"
        case .triangle: return "🔺"
        case .star: return "⭐"
        case .arc: return "🌙"
        case .stamp: return "🎯"
        case .selectCircle: return "⭕"
        case .selectSquare: return "⬜"
        }
    }
    
    /// Display name of the tool
    var name: String {
        switch self {
        case .pencil: return "Pencil"
        case .line: return "Line"
        case .eraser: return "Eraser"
        case .fill: return "Fill"
        case .spray: return "Spray"
        case .circle: return "Circle"
        case .square: return "Square"
        case .triangle: return "Triangle"
        case .star: return "Star"
        case .arc: return "Arc"
        case .stamp: return "Stamp"
        case .selectCircle: return "Select"
        case .selectSquare: return "Select"
        }
    }
    
    /// Keyboard shortcut key for the tool (numbers 1-9, 0, a, [, ])
    var keyboardShortcut: String? {
        switch self {
        case .pencil: return "1"
        case .line: return "2"
        case .eraser: return "3"
        case .fill: return "4"
        case .spray: return "5"
        case .circle: return "6"
        case .square: return "7"
        case .triangle: return "8"
        case .star: return "9"
        case .arc: return "a"
        case .stamp: return "0"
        case .selectCircle: return "["
        case .selectSquare: return "]"
        }
    }
}

/// Enumeration of fill patterns available for shapes
enum FillPattern: String, CaseIterable {
    case solid = "solid"
    case transparent = "transparent"
    case horizontal = "horizontal"
    case vertical = "vertical"
    case diagonal = "diagonal"
    case checkerboard = "checkerboard"
    case dots = "dots"
    
    /// Display name of the fill pattern
    var name: String {
        switch self {
        case .solid: return "Solid"
        case .transparent: return "Transparent"
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        case .diagonal: return "Diagonal"
        case .checkerboard: return "Checkerboard"
        case .dots: return "Dots"
        }
    }
}
