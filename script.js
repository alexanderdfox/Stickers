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
canvas.addEventListener('mouseout', stopDrawing);

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
}

function stopDrawing() {
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

function floodFill(startX, startY, fillColor) {
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const pixels = imageData.data;
    const startPos = (Math.floor(startY) * canvas.width + Math.floor(startX)) * 4;
    const startR = pixels[startPos];
    const startG = pixels[startPos + 1];
    const startB = pixels[startPos + 2];
    
    // Don't fill if clicking the same color
    if (startR === fillColor.r && startG === fillColor.g && startB === fillColor.b) {
        return;
    }
    
    const stack = [[Math.floor(startX), Math.floor(startY)]];
    const visited = new Set();
    
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
        
        pixels[pos] = fillColor.r;
        pixels[pos + 1] = fillColor.g;
        pixels[pos + 2] = fillColor.b;
        pixels[pos + 3] = 255;
        
        stack.push([x + 1, y]);
        stack.push([x - 1, y]);
        stack.push([x, y + 1]);
        stack.push([x, y - 1]);
    }
    
    ctx.putImageData(imageData, 0, 0);
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

