// EmojiPix - Kid Pix-style drawing app
const canvas = document.getElementById('drawing-canvas');
const ctx = canvas.getContext('2d');

// Set canvas size
canvas.width = 800;
canvas.height = 600;

// Initial settings
let isDrawing = false;
let currentTool = 'pencil';
let currentColor = '#FF0000';
let brushSize = 5;
let selectedEmoji = '😀';
let rainbowMode = false;
let sparkleMode = false;
let rainbowHue = 0;
let selectedFont = 'Arial';
let textCase = 'upper'; // 'upper' or 'lower'
let fillPattern = 'solid';
let secondaryColor = '#FFFFFF';
let shapeStartX = 0;
let shapeStartY = 0;

// Selection and clipboard
let clipboard = null;
let selectionData = null;
let selectionType = null; // 'circle' or 'square'
let selectionBounds = null;

// Audio context for sound effects
let audioContext = null;
let soundEnabled = true;

// Initialize audio context on first user interaction (iOS compatible)
function initAudio() {
    if (!audioContext) {
        try {
            audioContext = new (window.AudioContext || window.webkitAudioContext)();
            
            // iOS requires resuming the audio context
            if (audioContext.state === 'suspended') {
                audioContext.resume();
            }
        } catch (e) {
            console.log('Audio context not supported:', e);
            soundEnabled = false;
        }
    } else if (audioContext.state === 'suspended') {
        audioContext.resume();
    }
}

// Sound effect functions
function playSound(type, frequency = 440, duration = 0.1) {
    if (!soundEnabled || !audioContext) return;
    
    try {
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        switch(type) {
            case 'draw':
                oscillator.frequency.value = 200 + Math.random() * 100;
                oscillator.type = 'sine';
                gainNode.gain.setValueAtTime(0.05, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.05);
                duration = 0.05;
                break;
            case 'stamp':
                oscillator.frequency.value = 600;
                oscillator.type = 'square';
                gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.15);
                duration = 0.15;
                break;
            case 'spray':
                oscillator.frequency.value = 300 + Math.random() * 200;
                oscillator.type = 'sawtooth';
                gainNode.gain.setValueAtTime(0.03, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.03);
                duration = 0.03;
                break;
            case 'eraser':
                oscillator.frequency.value = 150 + Math.random() * 50;
                oscillator.type = 'sine';
                gainNode.gain.setValueAtTime(0.04, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.06);
                duration = 0.06;
                break;
            case 'fill':
                oscillator.frequency.value = 400;
                oscillator.type = 'triangle';
                gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
                duration = 0.3;
                // Add a sweep effect
                oscillator.frequency.exponentialRampToValueAtTime(800, audioContext.currentTime + 0.3);
                break;
            case 'clear':
                oscillator.frequency.value = 800;
                oscillator.type = 'square';
                gainNode.gain.setValueAtTime(0.15, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
                duration = 0.5;
                // Descending sweep
                oscillator.frequency.exponentialRampToValueAtTime(100, audioContext.currentTime + 0.5);
                break;
            case 'click':
                oscillator.frequency.value = 800;
                oscillator.type = 'sine';
                gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.08);
                duration = 0.08;
                break;
            case 'save':
                oscillator.frequency.value = 523.25; // C5
                oscillator.type = 'sine';
                gainNode.gain.setValueAtTime(0.15, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
                duration = 0.4;
                break;
            default:
                oscillator.frequency.value = frequency;
                gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
        }
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + duration);
    } catch (e) {
        console.log('Audio error:', e);
    }
}

// Play a chord for special effects
function playChord(frequencies, duration = 0.3) {
    if (!soundEnabled || !audioContext) return;
    
    frequencies.forEach((freq, index) => {
        setTimeout(() => {
            playSound('custom', freq, duration);
        }, index * 50);
    });
}

// Clear canvas to white
ctx.fillStyle = 'white';
ctx.fillRect(0, 0, canvas.width, canvas.height);

// Tool buttons
document.querySelectorAll('.tool-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playSound('click');
        document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
    });
});

// Color buttons
document.querySelectorAll('.color-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playSound('click');
        document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentColor = btn.dataset.color;
        rainbowMode = false;
    });
});

// Color picker (color wheel)
const colorPicker = document.getElementById('color-picker');
const colorHex = document.getElementById('color-hex');
if (colorPicker && colorHex) {
    colorPicker.addEventListener('input', (e) => {
        initAudio();
        currentColor = e.target.value;
        colorHex.textContent = e.target.value.toUpperCase();
        rainbowMode = false;
        document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
    });
}

// Brush size
const brushSizeSlider = document.getElementById('brush-size');
const sizeDisplay = document.getElementById('size-display');
brushSizeSlider.addEventListener('input', (e) => {
    brushSize = e.target.value;
    sizeDisplay.textContent = brushSize;
});

// Font selector
const fontSelector = document.getElementById('font-selector');
const fontPreview = document.getElementById('font-preview');
fontSelector.addEventListener('change', (e) => {
    initAudio();
    playSound('click');
    selectedFont = e.target.value;
    fontPreview.style.fontFamily = selectedFont;
    fontSelector.style.fontFamily = selectedFont;
});

// Case toggle buttons
document.querySelectorAll('.case-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playSound('click');
        document.querySelectorAll('.case-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        textCase = btn.dataset.case;
        updateFontPreview();
    });
});

function updateFontPreview() {
    if (textCase === 'upper') {
        fontPreview.innerHTML = '<span style="font-weight: 700;">ABC</span> <span style="opacity: 0.5;">abc</span> 123';
    } else {
        fontPreview.innerHTML = '<span style="opacity: 0.5;">ABC</span> <span style="font-weight: 700;">abc</span> 123';
    }
}

// Pattern buttons
document.querySelectorAll('.pattern-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playSound('click');
        document.querySelectorAll('.pattern-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        fillPattern = btn.dataset.pattern;
    });
});

// Secondary color picker
const secondaryColorPicker = document.getElementById('secondary-color');
if (secondaryColorPicker) {
    secondaryColorPicker.addEventListener('input', (e) => {
        initAudio();
        secondaryColor = e.target.value;
    });
}

// Selection action buttons
const copyBtn = document.getElementById('copy-btn');
const cutBtn = document.getElementById('cut-btn');
const pasteBtn = document.getElementById('paste-btn');

if (copyBtn) {
    copyBtn.addEventListener('click', () => {
        if (selectionData) {
            initAudio();
            playSound('click');
            clipboard = {
                imageData: selectionData,
                type: selectionType,
                bounds: selectionBounds
            };
            pasteBtn.disabled = false;
            selectionData = null;
            selectionBounds = null;
        }
    });
}

if (cutBtn) {
    cutBtn.addEventListener('click', () => {
        if (selectionData) {
            initAudio();
            playSound('click');
            clipboard = {
                imageData: selectionData,
                type: selectionType,
                bounds: selectionBounds
            };
            pasteBtn.disabled = false;
            
            // Clear the selected area
            clearSelection();
            selectionData = null;
            selectionBounds = null;
        }
    });
}

if (pasteBtn) {
    pasteBtn.addEventListener('click', () => {
        if (clipboard) {
            initAudio();
            playSound('click');
            currentTool = 'paste';
            // Switch to paste mode
        }
    });
}

// Emoji stamps
document.querySelectorAll('.emoji-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playSound('click');
        document.querySelectorAll('.emoji-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        selectedEmoji = btn.dataset.emoji;
        currentTool = 'stamp';
        document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
        document.querySelector('[data-tool="stamp"]').classList.add('active');
    });
});

// Effects
document.querySelectorAll('.effect-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playChord([523.25, 659.25, 783.99]); // C major chord
        const effect = btn.dataset.effect;
        if (effect === 'rainbow') {
            rainbowMode = !rainbowMode;
            sparkleMode = false;
            btn.style.opacity = rainbowMode ? '0.6' : '1';
        } else if (effect === 'sparkle') {
            sparkleMode = !sparkleMode;
            rainbowMode = false;
            btn.style.opacity = sparkleMode ? '0.6' : '1';
        }
    });
});

// Save button
document.getElementById('save-btn').addEventListener('click', () => {
    initAudio();
    playSound('save');
    
    // Create a temporary link element
    const link = document.createElement('a');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    link.download = `emojipix-${timestamp}.png`;
    
    // Convert canvas to PNG data URL
    link.href = canvas.toDataURL('image/png');
    
    // Trigger download
    link.click();
    
    // Optional: Show a fun confirmation
    console.log('🎨 Masterpiece saved!');
});

// Clear button
document.getElementById('clear-btn').addEventListener('click', () => {
    initAudio();
    if (confirm('🎨 Clear your masterpiece?')) {
        playSound('clear');
        // Fun Kid Pix-style clear animation
        clearCanvasWithAnimation();
    }
});

function clearCanvasWithAnimation() {
    let y = 0;
    const clearInterval = setInterval(() => {
        ctx.fillStyle = 'white';
        ctx.fillRect(0, y, canvas.width, 20);
        y += 20;
        if (y >= canvas.height) {
            clearInterval(clearInterval);
            ctx.fillStyle = 'white';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
        }
    }, 20);
}

// Mouse events
canvas.addEventListener('mousedown', startDrawing);
canvas.addEventListener('mousemove', draw);
canvas.addEventListener('mouseup', stopDrawing);
canvas.addEventListener('mouseout', (e) => {
    if (currentTool === 'circle' || currentTool === 'square' || currentTool === 'line' || 
        currentTool === 'select-circle' || currentTool === 'select-square') {
        // Don't complete action if mouse leaves canvas
        if (isDrawing) {
            isDrawing = false;
            ctx.beginPath();
        }
    } else {
        stopDrawing(e);
    }
});

// Touch events for mobile (iOS compatible)
canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    initAudio();
    const touch = e.touches[0];
    const rect = canvas.getBoundingClientRect();
    const mouseEvent = new MouseEvent('mousedown', {
        clientX: touch.clientX,
        clientY: touch.clientY,
        bubbles: true
    });
    canvas.dispatchEvent(mouseEvent);
}, { passive: false });

canvas.addEventListener('touchmove', (e) => {
    e.preventDefault();
    const touch = e.touches[0];
    const rect = canvas.getBoundingClientRect();
    const mouseEvent = new MouseEvent('mousemove', {
        clientX: touch.clientX,
        clientY: touch.clientY,
        bubbles: true
    });
    canvas.dispatchEvent(mouseEvent);
}, { passive: false });

canvas.addEventListener('touchend', (e) => {
    e.preventDefault();
    const mouseEvent = new MouseEvent('mouseup', {
        bubbles: true
    });
    canvas.dispatchEvent(mouseEvent);
}, { passive: false });

canvas.addEventListener('touchcancel', (e) => {
    e.preventDefault();
    const mouseEvent = new MouseEvent('mouseup', {
        bubbles: true
    });
    canvas.dispatchEvent(mouseEvent);
}, { passive: false });

function startDrawing(e) {
    initAudio();
    isDrawing = true;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    if (currentTool === 'fill') {
        playSound('fill');
        floodFill(x, y, hexToRgb(currentColor));
        isDrawing = false;
    } else if (currentTool === 'stamp') {
        playSound('stamp');
        stampEmoji(x, y);
        isDrawing = false;
    } else if (currentTool === 'paste' && clipboard) {
        playSound('stamp');
        pasteClipboard(x, y);
        isDrawing = false;
    } else if (currentTool === 'circle' || currentTool === 'square' || currentTool === 'line' || 
               currentTool === 'select-circle' || currentTool === 'select-square') {
        // Store starting position for shapes, lines, and selections
        shapeStartX = x;
        shapeStartY = y;
    } else {
        draw(e);
    }
}

function draw(e) {
    if (!isDrawing) return;
    
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    if (currentTool === 'pencil') {
        drawPencil(x, y);
    } else if (currentTool === 'eraser') {
        drawEraser(x, y);
    } else if (currentTool === 'spray') {
        drawSpray(x, y);
    }
    // Shapes are drawn on mouseup, not during drag
}

function stopDrawing(e) {
    if (!isDrawing) return;
    
    if (e) {
        const rect = canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        if (currentTool === 'circle') {
            drawCircle(shapeStartX, shapeStartY, x, y);
            playSound('stamp');
        } else if (currentTool === 'square') {
            drawSquare(shapeStartX, shapeStartY, x, y);
            playSound('stamp');
        } else if (currentTool === 'line') {
            drawLine(shapeStartX, shapeStartY, x, y);
            playSound('draw');
        } else if (currentTool === 'select-circle') {
            selectCircle(shapeStartX, shapeStartY, x, y);
            playSound('click');
        } else if (currentTool === 'select-square') {
            selectSquare(shapeStartX, shapeStartY, x, y);
            playSound('click');
        }
    }
    
    isDrawing = false;
    ctx.beginPath();
}

let lastSoundTime = 0;
const soundThrottle = 50; // milliseconds between sounds

function drawPencil(x, y) {
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = brushSize;
    
    if (rainbowMode) {
        rainbowHue = (rainbowHue + 2) % 360;
        ctx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        ctx.strokeStyle = currentColor;
    }
    
    ctx.lineTo(x, y);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x, y);
    
    // Play sound occasionally
    const now = Date.now();
    if (now - lastSoundTime > soundThrottle) {
        playSound('draw');
        lastSoundTime = now;
    }
    
    if (sparkleMode) {
        addSparkles(x, y);
    }
}

function drawEraser(x, y) {
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = brushSize * 2;
    ctx.strokeStyle = 'white';
    
    ctx.lineTo(x, y);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x, y);
    
    // Play sound occasionally
    const now = Date.now();
    if (now - lastSoundTime > soundThrottle) {
        playSound('eraser');
        lastSoundTime = now;
    }
}

function drawSpray(x, y) {
    const density = brushSize * 2;
    const radius = brushSize * 3;
    
    for (let i = 0; i < density; i++) {
        const offsetX = (Math.random() - 0.5) * radius;
        const offsetY = (Math.random() - 0.5) * radius;
        
        if (rainbowMode) {
            rainbowHue = (rainbowHue + 1) % 360;
            ctx.fillStyle = `hsl(${rainbowHue}, 100%, 50%)`;
        } else {
            ctx.fillStyle = currentColor;
        }
        
        ctx.fillRect(x + offsetX, y + offsetY, 2, 2);
    }
    
    // Play sound occasionally
    const now = Date.now();
    if (now - lastSoundTime > soundThrottle) {
        playSound('spray');
        lastSoundTime = now;
    }
    
    if (sparkleMode) {
        addSparkles(x, y);
    }
}

function stampEmoji(x, y) {
    const size = brushSize * 10;
    
    // Check if it's a text character (letter, number, or common punctuation)
    const isTextCharacter = /^[A-Za-z0-9!?&@#$%*+\-=/]$/.test(selectedEmoji);
    const isLetter = /^[A-Za-z]$/.test(selectedEmoji);
    
    // Apply case transformation to letters
    let charToStamp = selectedEmoji;
    if (isLetter) {
        charToStamp = textCase === 'upper' ? selectedEmoji.toUpperCase() : selectedEmoji.toLowerCase();
    }
    
    if (isTextCharacter) {
        // Use selected font for text characters
        ctx.font = `bold ${size}px "${selectedFont}", Arial, sans-serif`;
    } else {
        // Use default for emojis
        ctx.font = `${size}px Arial`;
    }
    
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    // Apply current color to text characters
    if (isTextCharacter) {
        if (rainbowMode) {
            ctx.fillStyle = `hsl(${rainbowHue}, 100%, 50%)`;
        } else {
            ctx.fillStyle = currentColor;
        }
    } else {
        // Emojis use default rendering
        ctx.fillStyle = '#000000';
    }
    
    ctx.fillText(charToStamp, x, y);
    
    // Fun bouncy effect
    let scale = 1.5;
    const bounceInterval = setInterval(() => {
        scale -= 0.1;
        if (scale <= 1) {
            clearInterval(bounceInterval);
        }
    }, 30);
}

function addSparkles(x, y) {
    const sparkleCount = 3;
    const sparkleRadius = brushSize * 2;
    
    for (let i = 0; i < sparkleCount; i++) {
        const sparkleX = x + (Math.random() - 0.5) * sparkleRadius;
        const sparkleY = y + (Math.random() - 0.5) * sparkleRadius;
        const sparkleSize = Math.random() * 3 + 1;
        
        ctx.fillStyle = '#FFFF00';
        ctx.beginPath();
        ctx.arc(sparkleX, sparkleY, sparkleSize, 0, Math.PI * 2);
        ctx.fill();
        
        // Draw star points
        ctx.fillStyle = '#FFFFFF';
        ctx.fillRect(sparkleX - sparkleSize/2, sparkleY, sparkleSize, 1);
        ctx.fillRect(sparkleX, sparkleY - sparkleSize/2, 1, sparkleSize);
    }
}

function createPattern() {
    if (fillPattern === 'solid') {
        return currentColor;
    }
    
    if (fillPattern === 'transparent') {
        return null; // Return null for transparent
    }
    
    const patternCanvas = document.createElement('canvas');
    const patternCtx = patternCanvas.getContext('2d');
    
    const color1 = currentColor;
    const color2 = secondaryColor;
    
    switch(fillPattern) {
        case 'horizontal':
            patternCanvas.width = 1;
            patternCanvas.height = 8;
            patternCtx.fillStyle = color1;
            patternCtx.fillRect(0, 0, 1, 4);
            patternCtx.fillStyle = color2;
            patternCtx.fillRect(0, 4, 1, 4);
            break;
            
        case 'vertical':
            patternCanvas.width = 8;
            patternCanvas.height = 1;
            patternCtx.fillStyle = color1;
            patternCtx.fillRect(0, 0, 4, 1);
            patternCtx.fillStyle = color2;
            patternCtx.fillRect(4, 0, 4, 1);
            break;
            
        case 'diagonal':
            patternCanvas.width = 10;
            patternCanvas.height = 10;
            patternCtx.fillStyle = color2;
            patternCtx.fillRect(0, 0, 10, 10);
            patternCtx.strokeStyle = color1;
            patternCtx.lineWidth = 3;
            patternCtx.beginPath();
            patternCtx.moveTo(0, 10);
            patternCtx.lineTo(10, 0);
            patternCtx.stroke();
            break;
            
        case 'checkerboard':
            patternCanvas.width = 16;
            patternCanvas.height = 16;
            patternCtx.fillStyle = color2;
            patternCtx.fillRect(0, 0, 16, 16);
            patternCtx.fillStyle = color1;
            patternCtx.fillRect(0, 0, 8, 8);
            patternCtx.fillRect(8, 8, 8, 8);
            break;
            
        case 'dots':
            patternCanvas.width = 12;
            patternCanvas.height = 12;
            patternCtx.fillStyle = color2;
            patternCtx.fillRect(0, 0, 12, 12);
            patternCtx.fillStyle = color1;
            patternCtx.beginPath();
            patternCtx.arc(6, 6, 3, 0, Math.PI * 2);
            patternCtx.fill();
            break;
    }
    
    return ctx.createPattern(patternCanvas, 'repeat');
}

function drawCircle(startX, startY, endX, endY) {
    const radius = Math.sqrt(Math.pow(endX - startX, 2) + Math.pow(endY - startY, 2));
    
    ctx.beginPath();
    ctx.arc(startX, startY, radius, 0, Math.PI * 2);
    
    const fillStyle = createPattern();
    if (fillStyle !== null) {
        ctx.fillStyle = fillStyle;
        ctx.fill();
    }
    
    ctx.strokeStyle = currentColor;
    ctx.lineWidth = Math.max(brushSize / 2, 2);
    ctx.stroke();
    
    if (sparkleMode) {
        addSparkles(startX, startY);
    }
}

function drawSquare(startX, startY, endX, endY) {
    const width = endX - startX;
    const height = endY - startY;
    
    ctx.beginPath();
    ctx.rect(startX, startY, width, height);
    
    const fillStyle = createPattern();
    if (fillStyle !== null) {
        ctx.fillStyle = fillStyle;
        ctx.fill();
    }
    
    ctx.strokeStyle = currentColor;
    ctx.lineWidth = Math.max(brushSize / 2, 2);
    ctx.stroke();
    
    if (sparkleMode) {
        addSparkles(startX + width/2, startY + height/2);
    }
}

function drawLine(startX, startY, endX, endY) {
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    
    if (rainbowMode) {
        ctx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        ctx.strokeStyle = currentColor;
    }
    
    ctx.lineWidth = brushSize;
    ctx.lineCap = 'round';
    ctx.stroke();
    
    if (sparkleMode) {
        addSparkles((startX + endX) / 2, (startY + endY) / 2);
    }
}

function selectCircle(startX, startY, endX, endY) {
    const radius = Math.sqrt(Math.pow(endX - startX, 2) + Math.pow(endY - startY, 2));
    
    // Get the bounding box
    const left = Math.max(0, Math.floor(startX - radius));
    const top = Math.max(0, Math.floor(startY - radius));
    const width = Math.min(canvas.width - left, Math.ceil(radius * 2));
    const height = Math.min(canvas.height - top, Math.ceil(radius * 2));
    
    // Get the image data
    const imageData = ctx.getImageData(left, top, width, height);
    
    // Create a mask for the circle
    const maskCanvas = document.createElement('canvas');
    maskCanvas.width = width;
    maskCanvas.height = height;
    const maskCtx = maskCanvas.getContext('2d');
    
    maskCtx.beginPath();
    maskCtx.arc(startX - left, startY - top, radius, 0, Math.PI * 2);
    maskCtx.fillStyle = 'white';
    maskCtx.fill();
    
    const maskData = maskCtx.getImageData(0, 0, width, height);
    
    // Apply mask to selection
    for (let i = 0; i < imageData.data.length; i += 4) {
        if (maskData.data[i] === 0) {
            imageData.data[i + 3] = 0; // Make transparent
        }
    }
    
    selectionData = imageData;
    selectionType = 'circle';
    selectionBounds = { x: startX, y: startY, radius: radius, left: left, top: top, width: width, height: height };
    
    // Draw selection outline
    ctx.save();
    ctx.strokeStyle = '#667eea';
    ctx.lineWidth = 2;
    ctx.setLineDash([5, 5]);
    ctx.beginPath();
    ctx.arc(startX, startY, radius, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();
}

function selectSquare(startX, startY, endX, endY) {
    const left = Math.min(startX, endX);
    const top = Math.min(startY, endY);
    const width = Math.abs(endX - startX);
    const height = Math.abs(endY - startY);
    
    // Get the image data
    const imageData = ctx.getImageData(left, top, width, height);
    
    selectionData = imageData;
    selectionType = 'square';
    selectionBounds = { left: left, top: top, width: width, height: height };
    
    // Draw selection outline
    ctx.save();
    ctx.strokeStyle = '#667eea';
    ctx.lineWidth = 2;
    ctx.setLineDash([5, 5]);
    ctx.strokeRect(left, top, width, height);
    ctx.restore();
}

function clearSelection() {
    if (!selectionBounds) return;
    
    ctx.fillStyle = 'white';
    if (selectionType === 'circle') {
        ctx.save();
        ctx.beginPath();
        ctx.arc(selectionBounds.x, selectionBounds.y, selectionBounds.radius, 0, Math.PI * 2);
        ctx.clip();
        ctx.fillRect(selectionBounds.left, selectionBounds.top, selectionBounds.width, selectionBounds.height);
        ctx.restore();
    } else if (selectionType === 'square') {
        ctx.fillRect(selectionBounds.left, selectionBounds.top, selectionBounds.width, selectionBounds.height);
    }
}

function pasteClipboard(x, y) {
    if (!clipboard) return;
    
    const imageData = clipboard.imageData;
    const bounds = clipboard.bounds;
    
    // Calculate paste position (centered on click)
    let pasteX = x - bounds.width / 2;
    let pasteY = y - bounds.height / 2;
    
    // Put the image data at the new position
    ctx.putImageData(imageData, pasteX, pasteY);
    
    if (sparkleMode) {
        addSparkles(x, y);
    }
}

function floodFill(startX, startY, fillColor) {
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const pixels = imageData.data;
    const startPos = (Math.floor(startY) * canvas.width + Math.floor(startX)) * 4;
    const startR = pixels[startPos];
    const startG = pixels[startPos + 1];
    const startB = pixels[startPos + 2];
    
    // Find the bounding box of the area to fill
    const stack = [[Math.floor(startX), Math.floor(startY)]];
    const visited = new Set();
    let minX = canvas.width, maxX = 0, minY = canvas.height, maxY = 0;
    
    // First pass: find all pixels to fill and calculate bounds
    while (stack.length > 0) {
        const [x, y] = stack.pop();
        const key = `${x},${y}`;
        
        if (visited.has(key)) continue;
        if (x < 0 || x >= canvas.width || y < 0 || y >= canvas.height) continue;
        
        visited.add(key);
        
        const pos = (y * canvas.width + x) * 4;
        const r = pixels[pos];
        const g = pixels[pos + 1];
        const b = pixels[pos + 2];
        
        if (r !== startR || g !== startG || b !== startB) continue;
        
        // Update bounds
        minX = Math.min(minX, x);
        maxX = Math.max(maxX, x);
        minY = Math.min(minY, y);
        maxY = Math.max(maxY, y);
        
        stack.push([x + 1, y]);
        stack.push([x - 1, y]);
        stack.push([x, y + 1]);
        stack.push([x, y - 1]);
    }
    
    // Put back the original image
    ctx.putImageData(imageData, 0, 0);
    
    if (visited.size === 0) return;
    
    // Create a temporary canvas for the pattern
    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = maxX - minX + 1;
    tempCanvas.height = maxY - minY + 1;
    const tempCtx = tempCanvas.getContext('2d');
    
    // Fill the temporary canvas with the pattern
    const fillStyle = createPattern();
    if (fillStyle !== null) {
        tempCtx.fillStyle = fillStyle;
        tempCtx.fillRect(0, 0, tempCanvas.width, tempCanvas.height);
    }
    
    // Get the pattern image data
    const patternData = tempCtx.getImageData(0, 0, tempCanvas.width, tempCanvas.height);
    
    // Second pass: apply the pattern to the visited pixels
    const finalImageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const finalPixels = finalImageData.data;
    
    visited.forEach(key => {
        const [x, y] = key.split(',').map(Number);
        const canvasPos = (y * canvas.width + x) * 4;
        
        // Calculate position in pattern
        const patternX = x - minX;
        const patternY = y - minY;
        const patternPos = (patternY * tempCanvas.width + patternX) * 4;
        
        if (fillStyle === null) {
            // For transparent, don't change the pixel
            return;
        }
        
        finalPixels[canvasPos] = patternData.data[patternPos];
        finalPixels[canvasPos + 1] = patternData.data[patternPos + 1];
        finalPixels[canvasPos + 2] = patternData.data[patternPos + 2];
        finalPixels[canvasPos + 3] = 255;
    });
    
    ctx.putImageData(finalImageData, 0, 0);
}

function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : { r: 0, g: 0, b: 0 };
}

// Initialize audio on first touch/click (iOS requirement)
document.addEventListener('touchstart', function initAudioOnTouch() {
    initAudio();
    // Remove listener after first touch
    document.removeEventListener('touchstart', initAudioOnTouch);
}, { once: true, passive: true });

document.addEventListener('click', function initAudioOnClick() {
    initAudio();
    // Remove listener after first click
    document.removeEventListener('click', initAudioOnClick);
}, { once: true });

// Prevent iOS double-tap zoom on buttons
const buttons = document.querySelectorAll('button, input[type="color"]');
buttons.forEach(button => {
    button.addEventListener('touchend', (e) => {
        e.preventDefault();
        button.click();
    }, { passive: false });
});

// Fix iOS viewport height issue
function setViewportHeight() {
    const vh = window.innerHeight * 0.01;
    document.documentElement.style.setProperty('--vh', `${vh}px`);
}

window.addEventListener('resize', setViewportHeight);
window.addEventListener('orientationchange', setViewportHeight);
setViewportHeight();

// Initialize font preview
if (fontPreview) {
    fontPreview.style.fontFamily = selectedFont;
    updateFontPreview();
}

console.log('🎨 EmojiPix loaded! Have fun drawing!');

