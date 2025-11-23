# 🎨 Stickers

A fun, Kid Pix-inspired drawing app where you can draw with emojis, create patterns, and unleash your creativity! Built with HTML5 Canvas and vanilla JavaScript.

## 🌟 Highlights

- **↶↷ Undo/Redo** - Full history management with 50-step memory and keyboard shortcuts
- **⌨️ Keyboard Shortcuts** - Number keys (1-9,0,[,]), zoom (+/-), and more for instant access
- **🔍 Canvas Zoom** - Zoom 25%-300% with +/- keys for detailed work
- **📐 Canvas Sizes** - 7 presets from 512×512 to 1920×1080 (Full HD)
- **💾 Export Resolutions** - Save at 50%, 100%, 200%, or 400% for any use case
- **🔄 Rotatable Stamps** - Mouse wheel (desktop) or two-finger twist (mobile) rotation
- **🔺⭐ 6 Shape Tools** - Circle, Square, Triangle, Star, plus Line and selection tools
- **📱 iOS & Mobile Optimized** - Full touch support with gestures, toast notifications, and adaptive UI
- **📑 Professional Layer System** - Multi-layer support with opacity, visibility, and reordering
- **🖱️ Dynamic Emoji Cursors** - See exactly what you'll stamp with real-time cursor preview
- **🏁 800+ Stamps** - Including flags from 80+ countries
- **🎨 Advanced Patterns** - 7 fill patterns with dual-color support
- **🔤 20 Fonts** - Full typography support with case toggle
- **🔊 Sound Effects** - Kid Pix-style audio feedback
- **✨ Special Effects** - Rainbow and sparkle modes for ALL tools
- **❓ Help System** - Built-in help modal with shortcuts and tips (F1 or ?)

## ✨ Features

### 🖌️ Drawing Tools

- **✏️ Pencil** - Classic freehand drawing (press **1**)
- **📏 Line** - Draw perfectly straight lines between two points (press **2**)
- **🧽 Eraser** - Remove mistakes (2x brush size) (press **3**)
- **🪣 Fill** - Flood fill areas with colors or patterns (press **4**)
- **💨 Spray Paint** - Spray can effect with random particle distribution (press **5**)
- **⭕ Circle** - Click and drag to draw circles of any size (press **6**)
- **⬜ Square/Rectangle** - Click and drag to draw rectangles (press **7**)
- **🔺 Triangle** - Click and drag to draw triangles (press **8**)
- **⭐ Star** - Click and drag to draw 5-pointed stars (press **9**)
- **🎯 Stamp** - Place emojis and text characters with rotation support (press **0**)

**All tools support Rainbow 🌈 and Sparkle ✨ effects!**

All shape tools (Circle, Square, Triangle, Star) support:
- All 7 fill patterns
- Rainbow color-changing strokes
- Sparkle effects at vertices and center
- Adjustable size and stroke width

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

- **⭕ Circle Select** - Select circular regions of any size (press **[**)
- **⬜ Rectangle Select** - Select rectangular areas (press **]**)
- **📋 Copy** - Copy selected area to clipboard (with toast confirmation)
- **✂️ Cut** - Cut selected area (makes transparent on layer)
- **📌 Paste** - Paste clipboard content anywhere on canvas
- Multiple paste support - paste the same selection multiple times!

**Mobile Features:**
- Thicker selection outlines (3px) for better visibility
- Toast notifications: "✓ Copied", "✓ Cut", "Tap canvas to paste"
- Minimum selection size (5px) prevents tiny accidental selections
- Touch-friendly copy/cut/paste buttons (44px minimum)
- Works perfectly on active layer with transparency

### 📏 Size & Zoom Control

#### Brush Size
- **Adjustable Brush Size** - 1-50 pixels
- **Live Preview** - See current size value
- **Gradient Slider** - Beautiful purple gradient slider
- Affects pencil width, eraser size, line thickness, shape borders, and stamp size
- **Size-Matched Cursor** - Emoji stamp cursor scales with brush size
- **Touch-Optimized** - No scrolling while adjusting on mobile

#### Canvas Zoom (Press + or -)
- **Zoom In** - Press **+** or click ➕ button (25% increments)
- **Zoom Out** - Press **-** or click ➖ button (25% decrements)
- **Zoom Range** - 25% to 300% for detailed work or overview
- **Reset Zoom** - Click "Reset Zoom" button to return to 100%
- **Smooth Animation** - Cubic-bezier easing for natural feel
- **Non-Destructive** - Zoom is visual only, doesn't affect canvas resolution

#### Canvas Size
- **7 Preset Sizes** - From 512×512 to 1920×1080 (Full HD)
  - 800×600 (Default)
  - 1024×768 (Large)
  - 1280×720 (HD 16:9)
  - 1920×1080 (Full HD)
  - 640×480 (Small)
  - 512×512 (Square)
  - 1080×1080 (Instagram Square)
- **Layer Preservation** - Content preserved when resizing (top-left aligned)
- **Confirmation Dialog** - Prevents accidental size changes
- **Undo Support** - Canvas resize tracked in history
- **Auto-Update** - Selector shows current canvas size

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
- **Redo** - Press **Ctrl/Cmd + Shift + Z** or **Ctrl + Y** or click ↷ Redo button
- **Smart State Management** - Automatically saves after:
  - Drawing with any tool (pencil, line, shapes, etc.)
  - Stamping emojis or text
  - Using fill tool
  - Pasting selections
  - Layer operations (add, delete, duplicate, merge, clear)
  - Cut operations (with transparency)
  - Opacity changes (debounced for performance)
- **Visual Feedback** - Buttons disabled when no undo/redo available
- **Layer-Aware** - Restores entire layer state including visibility and opacity
- **Cross-Platform** - Works on desktop (keyboard) and mobile (buttons)

### ❓ Help System

Built-in help modal for easy reference:

- **Open Help** - Press **F1** or **?** or click **❓ Help** button
- **Close Help** - Press **Escape** or click outside modal or click **✕**
- **Comprehensive Guide** - Lists all keyboard shortcuts and gestures
- **Platform-Specific** - Shows desktop shortcuts and mobile gestures
- **Beautiful Design** - Purple gradient header with smooth animations
- **Always Accessible** - Available from any tool or state
- **Touch-Friendly** - Large close button and scrollable content

### 💾 File Operations

#### Save with Export Resolution
- **💾 Save as PNG** - Download your artwork with timestamped filename (merges all visible layers)
- **Export Sizes:**
  - **100%** - Canvas size (default)
  - **200%** - 2× resolution for high-quality prints
  - **400%** - 4× resolution for ultra-high-res output
  - **50%** - Smaller file size for web sharing
- **Smart Scaling** - Maintains perfect quality when upscaling
- **Filename Format** - `stickers-YYYY-MM-DD-HH-MM-SS-2x.png` (includes scale if not 100%)
- **Toast Confirmation** - Shows exported size: "💾 Saved 1600×1200px PNG!"
- **Examples:**
  - 800×600 canvas at 200% = 1600×1200px export
  - 1920×1080 canvas at 400% = 7680×4320px export (print quality!)

#### Clear & Reset
- **🗑️ Clear Layer** - Kid Pix-style animated clear on active layer only (wipe-down effect)
- **Confirmation Dialog** - Prevents accidental clearing
- **Undo Available** - Clear operation tracked in history

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

Perfect mobile experience with comprehensive touch support:

#### Touch & Gestures
- **Single-Touch Drawing** - All drawing tools work smoothly
- **Two-Finger Rotation** - Twist gesture for stamp rotation (iOS/Android)
- **Touch-Optimized Buttons** - 44-48px minimum (Apple HIG compliant)
- **Smart Gesture Detection** - Prevents drawing during two-finger rotation
- **No Accidental Interactions** - Debounced button presses (500ms)
- **Slider Touch Control** - No scrolling while adjusting size/opacity

#### iOS-Specific Optimizations
- **Safari Compatible** - Full iOS Safari support
- **Color Picker Fix** - Reliable color selection on iOS
- **Safe Area Support** - Respects notch and bottom bar (env safe-area-inset)
- **Viewport Fixes** - Correct height with -webkit-fill-available
- **No Zoom** - Prevented double-tap zoom and pinch zoom
- **No Text Selection** - Disabled unwanted iOS text selection
- **Audio Context** - Properly initialized for iOS Web Audio
- **Overscroll Prevention** - No rubber-band effect or pull-to-refresh

#### Adaptive UI
- **Responsive Canvas** - Auto-resizes: 800x600→600x450 on mobile
- **Collapsed Layers** - Layer panel starts minimized on mobile for canvas space
- **Toast Notifications** - Visual feedback for copy/cut/paste actions
- **Larger Touch Targets** - All interactive elements 44px+
- **Momentum Scrolling** - Smooth native -webkit-overflow-scrolling
- **Better Spacing** - Optimized gaps and padding for touch
- **Help Modal** - Touch-friendly help system with platform-specific hints

#### Visual Feedback
- **Selection Outlines** - Thicker (3px) and larger dashes for visibility
- **Toast Messages** - "✓ Copied", "✓ Cut", "Tap canvas to paste"
- **Drawing Active State** - Canvas glows when actively drawing
- **Clear Confirmations** - Prevents accidental clearing

#### Performance
- **Optimized Canvas** - Smaller size on mobile for better performance
- **Smooth Scrolling** - Hardware-accelerated lists
- **Event Throttling** - Sound and render throttling
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
2. Start drawing immediately! No installation or dependencies required
3. **New to Stickers?** Press **F1** or **?** or click the **❓ Help** button for shortcuts and tips
4. **Mobile users:** Layer panel starts collapsed - tap the header to expand

### First Time Users
- Click any tool to start (or press **1** for Pencil)
- Try the **🌈 Rainbow** and **✨ Sparkle** effects - they work with ALL tools!
- Press **F1** or click **❓ Help** to see all keyboard shortcuts
- On mobile, all buttons are large and touch-friendly (44-48px minimum)

## 💻 Browser & Platform Support

### Desktop
- **Chrome/Edge** - Full support (Windows, macOS, Linux)
- **Firefox** - Full support (Windows, macOS, Linux)
- **Safari** - Full support (macOS)
- **All features** - Mouse, keyboard shortcuts, mouse wheel rotation

### Mobile & Tablet
- **iOS Safari** - Fully optimized (iPhone, iPad)
- **Chrome Mobile** - Full support (iOS, Android)
- **Firefox Mobile** - Full support (iOS, Android)
- **Samsung Internet** - Full support (Android)
- **Touch gestures** - Single-touch drawing, two-finger rotation
- **Responsive UI** - Adaptive canvas sizing and controls

### Features by Platform
| Feature | Desktop | Mobile/Tablet |
|---------|---------|---------------|
| All Drawing Tools | ✅ Mouse | ✅ Touch |
| Keyboard Shortcuts | ✅ 1-9,0,[,],Ctrl+Z | ✅ External Keyboard |
| Stamp Rotation | ✅ Mouse Wheel | ✅ Two-Finger Twist |
| Color Pickers | ✅ Click | ✅ Tap (iOS optimized) |
| Layer Panel | ✅ Full Size | ✅ Collapsible |
| Copy/Cut/Paste | ✅ Buttons | ✅ Buttons + Toasts |
| Undo/Redo | ✅ Ctrl+Z/Y | ✅ Buttons |
| Help Modal | ✅ F1 or ? | ✅ Help Button |

## 🎯 Usage Tips

### Creating Patterns
1. Select a shape tool (Circle, Square, Triangle, or Star)
2. Choose a fill pattern from 7 options
3. Pick primary and secondary colors
4. Drag on canvas to create patterned shapes!
5. Enable Rainbow mode for color-changing effects
6. Add Sparkle for extra visual flair

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
**Desktop:**
1. Select the Stamp tool (press **0**)
2. Choose any emoji or text character
3. Hover over canvas and scroll mouse wheel to rotate
4. Watch the cursor preview update in real-time
5. Press **R** to reset rotation to 0°
6. Click to place the rotated stamp

**Mobile:**
1. Tap the Stamp tool (🎯 Stamp button)
2. Choose any emoji or text character
3. Place two fingers on canvas and twist to rotate
4. Watch the rotation angle display update
5. Tap Reset button or (with keyboard) press **R** to reset
6. Tap canvas to place the rotated stamp

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
1. Choose your canvas size (📐 Canvas Size dropdown)
2. Start with the background layer for your base
3. Add a new layer for main subjects
4. Add another layer for details or effects
5. Use layer opacity to create shadows or highlights
6. Toggle layer visibility to work on specific elements
7. Zoom in (+) for detailed work, zoom out (-) for overview
8. Merge layers as you finish sections
9. Choose export resolution (50%-400%)
10. Save when complete (all visible layers are combined)

### Using Zoom for Detail Work
1. Press **+** key or click ➕ to zoom in (max 300%)
2. Work on fine details at higher zoom
3. Press **-** key or click ➖ to zoom out
4. Click **Reset Zoom** to return to 100%
5. Zoom is visual only - doesn't affect export size

### Exporting at Different Resolutions
1. Complete your artwork at your chosen canvas size
2. Select export resolution from dropdown:
   - **50%** for smaller file sizes (web thumbnails)
   - **100%** for original canvas resolution
   - **200%** for high-quality prints (2× pixels)
   - **400%** for ultra-high-resolution posters (4× pixels)
3. Click **💾 Save as PNG**
4. File downloads with resolution in filename (e.g., `-2x.png`)
5. Example: 1920×1080 canvas at 400% = 7680×4320px PNG!

## ⌨️ Keyboard Shortcuts

### Tool Selection (Press number keys 1-9, 0)
- **1** - Pencil ✏️
- **2** - Line 📏
- **3** - Eraser 🧽
- **4** - Fill 🪣
- **5** - Spray Paint 💨
- **6** - Circle ⭕
- **7** - Square ⬜
- **8** - Triangle 🔺
- **9** - Star ⭐
- **0** - Stamp 🎯
- **[** - Circle Select ⭕
- **]** - Rectangle Select ⬜

### History & Editing
- **Ctrl/Cmd + Z** - Undo (up to 50 steps)
- **Ctrl/Cmd + Shift + Z** or **Ctrl + Y** - Redo
- **R** - Reset stamp rotation to 0° (when stamp tool is active)

### Zoom Controls
- **+** or **=** - Zoom in (25% increments, up to 300%)
- **-** - Zoom out (25% decrements, down to 25%)
- Click **Reset Zoom** button to return to 100%

### Stamp Tool Rotation
- **Desktop:** Mouse wheel up/down to rotate (15° per notch)
- **Mobile:** Two-finger twist gesture for smooth rotation
- **Both:** Press **R** to reset rotation to 0°

### Help & Navigation
- **F1** or **?** - Open help modal (with all shortcuts and tips)
- **Escape** - Close help modal

All shortcuts work globally except when typing in input fields.

## 📝 Technical Details

- **Canvas Sizes**: 7 presets from 512×512 to 1920×1080 (user-selectable, with resize preservation)
- **Default Size**: 800×600 pixels (auto-adjusts to ~600×450 on mobile for performance)
- **Zoom Levels**: 25% to 300% in 25% increments (visual scaling, non-destructive)
- **Export Resolutions**: 50%, 100%, 200%, 400% (up to 7680×4320 for 4K displays)
- **Color Depth**: 32-bit RGBA with full alpha channel support
- **Layer System**: Multi-layer architecture with transparency, opacity, and blending
- **History Management**: 50-step undo/redo with full layer state restoration (includes canvas resizing)
- **Keyboard Support**: Number keys (1-9,0,[,]), zoom (+/-), editing (Ctrl+Z), help (F1/?)
- **Dynamic Cursors**: Real-time emoji/character cursor generation with rotation preview
- **Stamp Rotation**: 360° rotation - mouse wheel (desktop) or two-finger gesture (mobile)
- **Audio**: Web Audio API for sound synthesis with pitch variation
- **Patterns**: Dynamic canvas pattern generation with rainbow support
- **Touch Gestures**: Single-touch drawing, two-finger rotation, smart gesture conflict prevention
- **Performance**: Optimized for smooth 60fps drawing with multiple layers (tested up to Full HD)
- **Responsive**: Adaptive canvas sizing, collapsible panels, touch-optimized controls
- **Cross-Platform**: Desktop (mouse+keyboard), Mobile (touch+gestures), Tablet (hybrid)

## 🛠️ Built With

- **HTML5 Canvas** - Drawing surface
- **Vanilla JavaScript** - No frameworks!
- **CSS3** - Modern styling with gradients and animations
- **Web Audio API** - Sound effects

## 🎮 Kid Pix Inspiration

This project is inspired by the classic Kid Pix drawing program, featuring:
- Fun sound effects with Web Audio API (pitch-shifting, chords)
- 800+ emoji stamps (instead of classic stamps)
- Animated wipe-down clear effect
- Spray paint tool with particle effects
- Easy-to-use colorful interface
- Modern enhancements that go far beyond the original:
  - **Undo/Redo system** with 50-step history (Ctrl+Z/Y)
  - **Keyboard shortcuts** for instant tool switching (1-9,0,[,])
  - **Rotatable stamps** - mouse wheel (desktop) or two-finger twist (mobile)
  - **6 shape tools** - Circle, Square, Triangle, Star, plus Line
  - **Rainbow & Sparkle** effects for ALL tools (not just some!)
  - **Professional layer system** with opacity, visibility, reordering
  - **Dynamic emoji cursors** with live rotation preview
  - **Advanced pattern fills** - 7 patterns with dual colors
  - **Full iOS & Android support** - touch gestures, adaptive UI, toast feedback
  - **Built-in help system** - Press F1 or ? for shortcuts
  - **Copy/Cut/Paste** with layer awareness and transparency
  - **20 font choices** with case toggle for text stamps
  - **Responsive design** - Works on phone, tablet, and desktop
  - **Visual feedback** - Toast notifications, selection outlines, drawing glow
- Creative freedom for all ages, on any device!

### What Makes Stickers Special
- **Cross-platform perfection** - Identical experience on desktop and mobile
- **Professional tools** - 6 shape tools, all with patterns and effects
- **Flexible canvas** - 7 preset sizes (512×512 to 1920×1080) with resize preservation
- **Zoom capability** - 25%-300% zoom for detail work without changing resolution
- **Export versatility** - Save at 50%-400% scale for any use case (web to print)
- **Layer-aware operations** - Copy, paste, and all edits respect layers
- **Smart touch detection** - Two-finger gestures don't interfere with drawing
- **Comprehensive undo** - Every action tracked, including canvas size changes
- **Effect versatility** - Rainbow and Sparkle work with every single tool
- **Visual feedback** - Toast notifications, selection outlines, drawing glow
- **Accessibility** - Large touch targets (44-48px), clear visual feedback, help modal
- **No framework bloat** - Pure vanilla JavaScript for speed
- **Offline ready** - Works without internet after first load

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

Free to use, modify, and distribute!

## 🌟 Credits

Created with ❤️ for creative minds everywhere!

---

**Have fun drawing! 🎨✨**

