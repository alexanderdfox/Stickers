# 🎨 EmojiPix

A fun, Kid Pix-inspired drawing app where you can draw with emojis, create patterns, and unleash your creativity! Built with HTML5 Canvas and vanilla JavaScript.

## 🌟 Highlights

- **📑 Professional Layer System** - Multi-layer support with opacity, visibility, and reordering
- **🖱️ Dynamic Emoji Cursors** - See exactly what you'll stamp with real-time cursor preview
- **🏁 800+ Stamps** - Including flags from 80+ countries
- **🎨 Advanced Patterns** - 7 fill patterns with dual-color support
- **🔤 20 Fonts** - Full typography support with case toggle
- **📱 Mobile Optimized** - Touch-friendly interface for iOS and Android
- **🔊 Sound Effects** - Kid Pix-style audio feedback
- **✨ Special Effects** - Rainbow mode and sparkle effects

## ✨ Features

### 🖌️ Drawing Tools

- **✏️ Pencil** - Classic freehand drawing
- **📏 Line** - Draw perfectly straight lines between two points
- **🧽 Eraser** - Remove mistakes (2x brush size)
- **🪣 Fill** - Flood fill areas with colors or patterns
- **💨 Spray Paint** - Spray can effect with random particle distribution
- **⭕ Circle** - Click and drag to draw circles of any size
- **⬜ Square/Rectangle** - Click and drag to draw rectangles
- **🎯 Stamp** - Place emojis and text characters on your canvas

### 🎨 Color System

- **Color Palette** - 12 preset vibrant colors for quick selection
- **🎨 32-bit Color Wheel** - Pick from 16.7 million colors
- **Secondary Color Picker** - For two-color patterns
- **Live Hex Display** - See the current color code
- **🌈 Rainbow Mode** - Draw in continuously changing rainbow colors
- **✨ Sparkle Mode** - Add sparkle effects as you draw

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

- **⭕ Circle Select** - Select circular regions of any size
- **⬜ Rectangle Select** - Select rectangular areas
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
1. Select the Line tool
2. Click starting point
3. Drag to endpoint
4. Release to draw the line

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

## 🎨 Keyboard Shortcuts

Currently, all functions are accessible via the toolbar interface. Keyboard shortcuts may be added in future versions.

## 📝 Technical Details

- **Canvas Size**: 800x600 pixels per layer
- **Color Depth**: 32-bit RGBA
- **Layer System**: Multi-layer architecture with transparency and blending
- **Dynamic Cursors**: Real-time emoji/character cursor generation
- **Audio**: Web Audio API for sound synthesis
- **Patterns**: Dynamic canvas pattern generation
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
  - Professional layer system
  - Dynamic emoji cursors
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

