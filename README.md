# 🎨 EmojiPix

A fun, Kid Pix-inspired drawing app where you can draw with emojis, create patterns, and unleash your creativity! Built with HTML5 Canvas and vanilla JavaScript.

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

#### 700+ Emoji Stamps
Organized in 8 categories:
- **😊 Smileys** - 90+ faces and expressions
- **🐶 Animals** - 100+ animals, birds, and sea creatures
- **🌸 Nature** - 68+ plants, weather, and celestial objects
- **🍕 Food** - 99+ fruits, meals, and desserts
- **⚽ Activities** - 70+ sports, music, and games
- **🚗 Travel** - 84+ vehicles and landmarks
- **🎈 Objects** - 133+ everyday items and tech
- **❤️ Symbols** - 110+ hearts, signs, and icons

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

### 💾 File Operations

- **💾 Save as PNG** - Download your artwork with timestamped filename
- **🗑️ Clear All** - Kid Pix-style animated clear (wipe-down effect)
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

## 🎨 Keyboard Shortcuts

Currently, all functions are accessible via the toolbar interface. Keyboard shortcuts may be added in future versions.

## 📝 Technical Details

- **Canvas Size**: 800x600 pixels
- **Color Depth**: 32-bit RGBA
- **Audio**: Web Audio API for sound synthesis
- **Patterns**: Dynamic canvas pattern generation
- **Performance**: Optimized for smooth 60fps drawing

## 🛠️ Built With

- **HTML5 Canvas** - Drawing surface
- **Vanilla JavaScript** - No frameworks!
- **CSS3** - Modern styling with gradients and animations
- **Web Audio API** - Sound effects

## 🎮 Kid Pix Inspiration

This project is inspired by the classic Kid Pix drawing program, featuring:
- Fun sound effects
- Emoji stamps (instead of classic stamps)
- Animated clear effect
- Spray paint tool
- Easy-to-use interface
- Creative freedom!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

Free to use, modify, and distribute!

## 🌟 Credits

Created with ❤️ for creative minds everywhere!

---

**Have fun drawing! 🎨✨**

