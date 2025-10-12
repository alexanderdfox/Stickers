# 🎨 EmojiPix

A fun, Kid Pix-inspired drawing app where you can draw with emojis, create patterns, and unleash your creativity! Built with HTML5 Canvas and vanilla JavaScript.

## 🌟 Highlights

- **↶↷ Undo/Redo** - Full history management with 50-step memory and keyboard shortcuts
- **⌨️ Keyboard Shortcuts** - Number keys (1-9,0) for instant tool switching
- **🔄 Rotatable Stamps** - Mouse wheel rotation for emoji/text stamps
- **📑 Professional Layer System** - Multi-layer support with opacity, visibility, and reordering
- **🖱️ Dynamic Emoji Cursors** - See exactly what you'll stamp with real-time cursor preview
- **🏁 800+ Stamps** - Including flags from 80+ countries
- **🎨 Advanced Patterns** - 7 fill patterns with dual-color support
- **🔤 20 Fonts** - Full typography support with case toggle
- **📱 Mobile Optimized** - Touch-friendly interface for iOS and Android
- **🔊 Sound Effects** - Kid Pix-style audio feedback
- **✨ Special Effects** - Rainbow and sparkle modes for ALL tools

## ✨ Features

### 🖌️ Drawing Tools

- **✏️ Pencil** - Classic freehand drawing (press **1**)
- **📏 Line** - Draw perfectly straight lines between two points (press **2**)
- **🧽 Eraser** - Remove mistakes (2x brush size) (press **3**)
- **🪣 Fill** - Flood fill areas with colors or patterns (press **4**)
- **💨 Spray Paint** - Spray can effect with random particle distribution (press **5**)
- **⭕ Circle** - Click and drag to draw circles of any size (press **6**)
- **⬜ Square/Rectangle** - Click and drag to draw rectangles (press **7**)
- **🎯 Stamp** - Place emojis and text characters with rotation support (press **8**)

**All tools support Rainbow 🌈 and Sparkle ✨ effects!**

### 🎨 Color System

- **Color Palette** - 12 preset vibrant colors for quick selection
- **🎨 32-bit Color Wheel** - Pick from 16.7 million colors
- **Secondary Color Picker** - For two-color patterns
- **Live Hex Display** - See the current color code
- **🌈 Rainbow Mode** - Draw in continuously changing rainbow colors (works with ALL tools!)
  - Pencil, Line, Spray, Stamp text, Circle/Square strokes, and Fill!
- **✨ Sparkle Mode** - Add sparkle effects as you draw (works with ALL tools!)
  - Sparkles appear with Pencil, Line, Spray, Stamp, Circle, Square, and Fill!

### 🎭 Fill Patterns

Choose from 7 different fill patterns for shapes:
- **Solid** - Single color fill
- **Transparent** - Outline only (no fill)
- **Horizontal Stripes** - Two-color horizontal lines
- **Vertical Stripes** - Two-color vertical lines
- **Diagonal Stripes** - Two-color diagonal pattern
- **Checkerboard** - Classic chess board pattern
- **Dots** - Polka dot pattern

All patterns work with circles, squares, and the fill tool!

### 🔤 Text & Emoji Stamps

#### Alphabet & Numbers
- **A-Z** - All uppercase letters
- **0-9** - All digits
- **Punctuation** - ! ? & @ # $ % * + - = /
- **Case Toggle** - Switch between uppercase (ABC) and lowercase (abc)
- **20 Fonts** - Arial, Times New Roman, Comic Sans MS, Impact, and more!
- **Font Preview** - See your selected font before stamping
- **Dynamic Cursor** - See exactly what emoji/character you'll stamp before clicking!
- **🔄 Rotation** - Use mouse wheel to rotate stamps by 15° increments
- **Reset Rotation** - Press **R** to reset to 0° or click reset button

#### 800+ Emoji Stamps
Organized in 9 categories:
- **😊 Smileys** - 90+ faces and expressions
- **🐶 Animals** - 100+ animals, birds, and sea creatures
- **🌸 Nature** - 68+ plants, weather, and celestial objects
- **🍕 Food** - 99+ fruits, meals, and desserts
- **⚽ Activities** - 70+ sports, music, and games
- **🚗 Travel** - 84+ vehicles and landmarks
- **🎈 Objects** - 133+ everyday items and tech
- **❤️ Symbols** - 110+ hearts, signs, and icons
- **🏁 Flags** - 80+ country flags and special flags (checkered, rainbow, pirate, etc.)

### ✂️ Selection & Clipboard

- **⭕ Circle Select** - Select circular regions of any size (press **9**)
- **⬜ Rectangle Select** - Select rectangular areas (press **0**)
- **📋 Copy** - Copy selected area to clipboard
- **✂️ Cut** - Cut selected area (clears to white)
- **📌 Paste** - Paste clipboard content anywhere on canvas
- Multiple paste support - paste the same selection multiple times!

### 📏 Size Control

- **Adjustable Brush Size** - 1-50 pixels
- **Live Preview** - See current size value
- **Gradient Slider** - Beautiful purple gradient slider
- Affects pencil width, eraser size, line thickness, shape borders, and stamp size
- **Size-Matched Cursor** - Emoji stamp cursor scales with brush size

### 📑 Layer Manager

Professional multi-layer support for complex artwork:

#### Layer Controls
- **➕ Add Layer** - Create new transparent layers
- **🗑️ Delete Layer** - Remove active layer (cannot delete last layer)
- **📋 Duplicate Layer** - Clone the current layer with all content
- **⬇️ Merge Down** - Merge active layer with the one below

#### Layer Management
- **Visual Thumbnails** - See preview of each layer's content
- **Layer Visibility** - Toggle individual layers on/off (👁️ icon)
- **Layer Reordering** - Use ▲▼ arrows to change layer stack order
- **Rename Layers** - Double-click layer name to edit
- **Active Layer Highlight** - Purple highlight shows which layer you're drawing on
- **Opacity Control** - Adjust active layer opacity from 0-100%
- **Collapsible Panel** - Click header to expand/collapse

#### Layer Features
- **Independent Drawing** - Each layer is a separate drawing surface
- **Background Layer** - Starts with white background (Layer 1)
- **Transparent Layers** - New layers are transparent for perfect blending
- **Real-time Rendering** - See all layers combined as you draw
- **Layer-Aware Tools** - All drawing tools work on the active layer
- **Smart Save** - Save button merges all visible layers
- **Layer-Specific Clear** - Clear button only affects active layer

### ↶↷ Undo/Redo System

Full history management for worry-free creativity:

- **50-Step History** - Stores up to 50 actions in memory
- **Undo** - Press **Ctrl/Cmd + Z** or click ↶ Undo button
- **Redo** - Press **Ctrl/Cmd + Shift + Z** or click ↷ Redo button
- **Smart State Management** - Automatically saves after:
  - Drawing with any tool (pencil, line, shapes, etc.)
  - Stamping emojis or text
  - Using fill tool
  - Pasting selections
  - Layer operations (add, delete, duplicate, merge, clear)
  - Opacity changes (debounced for performance)
- **Visual Feedback** - Buttons disabled when no undo/redo available
- **Layer-Aware** - Restores entire layer state including visibility and opacity

### 💾 File Operations

- **💾 Save as PNG** - Download your artwork with timestamped filename (merges all visible layers)
- **🗑️ Clear Layer** - Kid Pix-style animated clear on active layer only (wipe-down effect)
- **Confirmation Dialog** - Prevents accidental clearing

### 🔊 Sound Effects

Synthesized sound effects using Web Audio API:
- **Tool Selection** - Click sounds
- **Drawing** - Continuous draw sounds (pencil, spray, eraser)
- **Shapes** - Stamp sound when complete
- **Fill** - Ascending sweep effect
- **Stamps** - Pop sound for emojis and text
- **Effects Toggle** - Musical chord
- **Save** - Pleasant tone (C5 note)
- **Clear** - Descending sweep

All sounds are throttled and non-intrusive!

### 📱 Mobile & iOS Support

- **Touch Events** - Full touch screen support
- **iOS Optimized** - Works perfectly on iPhone and iPad
- **Safe Area Support** - Respects notch and bottom bar
- **Viewport Fixes** - Correct height on all mobile browsers
- **Larger Touch Targets** - 48px+ buttons for easy tapping
- **Momentum Scrolling** - Smooth native iOS scrolling
- **Audio Context** - Properly initialized for iOS
- **No Zoom/Selection** - Prevents unwanted interactions
- **PWA Ready** - Can be added to home screen

### 🎨 Professional Design

- **Modern UI** - Clean, professional interface
- **System Fonts** - Native font stack for optimal rendering
- **Smooth Animations** - Cubic-bezier easing for natural motion
- **Gradient Accents** - Beautiful purple theme throughout
- **Custom Scrollbars** - Styled for consistency
- **Hover Effects** - Visual feedback on all interactions
- **Responsive Layout** - Works on desktop, tablet, and mobile
- **Three Breakpoints** - 1024px, 768px, 480px

## 🚀 Getting Started

1. Open `index.html` in a modern web browser
2. Start drawing immediately!
3. No installation or dependencies required

## 💻 Browser Support

- **Chrome/Edge** - Full support
- **Firefox** - Full support
- **Safari** - Full support (including iOS)
- **Mobile Browsers** - Full touch support

## 🎯 Usage Tips

### Creating Patterns
1. Select a shape tool (Circle or Square)
2. Choose a fill pattern
3. Pick primary and secondary colors
4. Drag on canvas to create patterned shapes!

### Text Art
1. Select letters from the alphabet stamps
2. Choose a font style
3. Toggle between uppercase/lowercase
4. Select colors and size
5. Click to stamp letters on canvas

### Copy/Paste Workflow
1. Use Circle or Rectangle Select tool
2. Drag to select an area (see dashed outline)
3. Click Copy or Cut
4. Click Paste, then click anywhere to place it
5. Create patterns by pasting multiple times!

### Drawing Straight Lines
1. Select the Line tool (press **2**)
2. Click starting point
3. Drag to endpoint
4. Release to draw the line

### Rotating Stamps
1. Select the Stamp tool (press **8**)
2. Choose any emoji or text character
3. Hover over canvas and scroll mouse wheel to rotate
4. Watch the cursor preview update in real-time
5. Press **R** to reset rotation to 0°
6. Click to place the rotated stamp

### Working with Layers
1. Click ➕ to add a new layer
2. Select a layer by clicking it in the layer panel
3. Draw on the active layer (highlighted in purple)
4. Toggle visibility with the 👁️ icon to see layers individually
5. Adjust opacity slider for transparency effects
6. Use ▲▼ to reorder layers
7. Duplicate layers to create variations
8. Merge down when you're happy with the result

### Creating Complex Artwork
1. Start with the background layer for your base
2. Add a new layer for main subjects
3. Add another layer for details or effects
4. Use layer opacity to create shadows or highlights
5. Toggle layer visibility to work on specific elements
6. Merge layers as you finish sections
7. Save when complete (all visible layers are combined)

## ⌨️ Keyboard Shortcuts

### Tool Selection (Press number keys 1-9, 0)
- **1** - Pencil ✏️
- **2** - Line 📏
- **3** - Eraser 🧽
- **4** - Fill 🪣
- **5** - Spray Paint 💨
- **6** - Circle ⭕
- **7** - Square ⬜
- **8** - Stamp 🎯
- **9** - Circle Select ⭕
- **0** - Rectangle Select ⬜

### History & Editing
- **Ctrl/Cmd + Z** - Undo (up to 50 steps)
- **Ctrl/Cmd + Shift + Z** or **Ctrl + Y** - Redo
- **R** - Reset stamp rotation to 0° (when stamp tool is active)

### Stamp Tool
- **Mouse Wheel Up** - Rotate stamp counter-clockwise (15° per notch)
- **Mouse Wheel Down** - Rotate stamp clockwise (15° per notch)
- **R** - Reset rotation to 0°

All shortcuts work globally except when typing in input fields.

## 📝 Technical Details

- **Canvas Size**: 800x600 pixels per layer
- **Color Depth**: 32-bit RGBA
- **Layer System**: Multi-layer architecture with transparency and blending
- **History Management**: 50-step undo/redo with full layer state restoration
- **Keyboard Support**: Number key shortcuts (1-9, 0) + standard editing shortcuts
- **Dynamic Cursors**: Real-time emoji/character cursor generation with rotation
- **Stamp Rotation**: 360° rotation with 15° increments via mouse wheel
- **Audio**: Web Audio API for sound synthesis with pitch variation
- **Patterns**: Dynamic canvas pattern generation with rainbow support
- **Performance**: Optimized for smooth 60fps drawing with multiple layers

## 🛠️ Built With

- **HTML5 Canvas** - Drawing surface
- **Vanilla JavaScript** - No frameworks!
- **CSS3** - Modern styling with gradients and animations
- **Web Audio API** - Sound effects

## 🎮 Kid Pix Inspiration

This project is inspired by the classic Kid Pix drawing program, featuring:
- Fun sound effects with Web Audio API
- 800+ emoji stamps (instead of classic stamps)
- Animated wipe-down clear effect
- Spray paint tool with particle effects
- Easy-to-use colorful interface
- Modern enhancements:
  - **Undo/Redo system** with 50-step history
  - **Keyboard shortcuts** for instant tool switching
  - **Rotatable stamps** with mouse wheel control
  - **Rainbow & Sparkle** effects for ALL tools
  - Professional layer system
  - Dynamic emoji cursors with rotation
  - Advanced pattern fills
  - Mobile touch support
  - 20 font choices
- Creative freedom for all ages!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

Free to use, modify, and distribute!

## 🌟 Credits

Created with ❤️ for creative minds everywhere!

---

**Have fun drawing! 🎨✨**

