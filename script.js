// EmojiPix - Kid Pix-style drawing app
const canvas = document.getElementById('drawing-canvas');
const ctx = canvas.getContext('2d');

// Set canvas size - responsive for mobile
function setCanvasSize() {
    if (window.innerWidth <= 768) {
        // Mobile: smaller canvas for better performance
        const maxWidth = Math.min(600, window.innerWidth - 40);
        const maxHeight = Math.min(450, window.innerHeight * 0.5);
        canvas.width = maxWidth;
        canvas.height = maxHeight;
    } else {
        // Desktop: full size
        canvas.width = 800;
        canvas.height = 600;
    }
}

setCanvasSize();

// Layer Management
let layers = [];
let activeLayerIndex = 0;
let layerIdCounter = 0;

// History Management for Undo/Redo
let history = [];
let historyStep = -1;
const MAX_HISTORY = 50;

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
let stampRotation = 0; // Rotation angle in degrees for stamp tool

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

// Layer Management Functions
function createLayer(name = null) {
    const layerCanvas = document.createElement('canvas');
    layerCanvas.width = canvas.width;
    layerCanvas.height = canvas.height;
    const layerCtx = layerCanvas.getContext('2d');
    
    // Initialize with transparent background
    layerCtx.clearRect(0, 0, layerCanvas.width, layerCanvas.height);
    
    const layer = {
        id: layerIdCounter++,
        name: name || `Layer ${layerIdCounter}`,
        canvas: layerCanvas,
        ctx: layerCtx,
        visible: true,
        opacity: 1.0
    };
    
    return layer;
}

function initializeLayers() {
    // Clear any existing layers
    layers = [];
    
    // Create background layer with white background
    const backgroundLayer = createLayer('Background');
    backgroundLayer.ctx.fillStyle = 'white';
    backgroundLayer.ctx.fillRect(0, 0, backgroundLayer.canvas.width, backgroundLayer.canvas.height);
    layers.push(backgroundLayer);
    
    activeLayerIndex = 0;
    renderCanvas();
    updateLayersList();
}

function getActiveLayer() {
    return layers[activeLayerIndex];
}

function getActiveContext() {
    return layers[activeLayerIndex]?.ctx || ctx;
}

function renderCanvas() {
    // Clear main canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Render all visible layers from bottom to top
    for (let i = layers.length - 1; i >= 0; i--) {
        const layer = layers[i];
        if (layer.visible) {
            ctx.save();
            ctx.globalAlpha = layer.opacity;
            ctx.drawImage(layer.canvas, 0, 0);
            ctx.restore();
        }
    }
}

function addLayer() {
    initAudio();
    playSound('click');
    const newLayer = createLayer();
    layers.unshift(newLayer); // Add to top
    activeLayerIndex = 0;
    renderCanvas();
    updateLayersList();
    saveHistory();
}

function deleteLayer() {
    if (layers.length <= 1) {
        return; // Don't delete the last layer
    }
    
    initAudio();
    playSound('click');
    layers.splice(activeLayerIndex, 1);
    if (activeLayerIndex >= layers.length) {
        activeLayerIndex = layers.length - 1;
    }
    renderCanvas();
    updateLayersList();
    saveHistory();
}

function duplicateLayer() {
    initAudio();
    playSound('click');
    const sourceLayer = layers[activeLayerIndex];
    const newLayer = createLayer(`${sourceLayer.name} copy`);
    newLayer.ctx.drawImage(sourceLayer.canvas, 0, 0);
    newLayer.opacity = sourceLayer.opacity;
    layers.splice(activeLayerIndex, 0, newLayer); // Insert above current
    activeLayerIndex = activeLayerIndex; // Keep same index (which is now the new layer)
    renderCanvas();
    updateLayersList();
    saveHistory();
}

function mergeLayerDown() {
    if (activeLayerIndex >= layers.length - 1) {
        return; // Can't merge bottom layer
    }
    
    initAudio();
    playSound('click');
    const currentLayer = layers[activeLayerIndex];
    const belowLayer = layers[activeLayerIndex + 1];
    
    // Merge current layer into the one below
    belowLayer.ctx.save();
    belowLayer.ctx.globalAlpha = currentLayer.opacity;
    belowLayer.ctx.drawImage(currentLayer.canvas, 0, 0);
    belowLayer.ctx.restore();
    
    // Remove current layer
    layers.splice(activeLayerIndex, 1);
    // activeLayerIndex automatically points to the merged layer now
    
    renderCanvas();
    updateLayersList();
    saveHistory();
}

function setActiveLayer(index) {
    activeLayerIndex = index;
    updateLayersList();
    updateLayerOpacityControl();
}

function toggleLayerVisibility(index) {
    initAudio();
    playSound('click');
    layers[index].visible = !layers[index].visible;
    renderCanvas();
    updateLayersList();
}

function moveLayer(fromIndex, toIndex) {
    if (toIndex < 0 || toIndex >= layers.length) return;
    
    initAudio();
    playSound('click');
    const [layer] = layers.splice(fromIndex, 1);
    layers.splice(toIndex, 0, layer);
    
    // Update active index if needed
    if (fromIndex === activeLayerIndex) {
        activeLayerIndex = toIndex;
    } else if (fromIndex < activeLayerIndex && toIndex >= activeLayerIndex) {
        activeLayerIndex--;
    } else if (fromIndex > activeLayerIndex && toIndex <= activeLayerIndex) {
        activeLayerIndex++;
    }
    
    renderCanvas();
    updateLayersList();
}

function setLayerOpacity(opacity) {
    layers[activeLayerIndex].opacity = opacity;
    renderCanvas();
    updateThumbnail(activeLayerIndex);
}

function updateThumbnail(index) {
    const layer = layers[index];
    const thumbnailCanvas = document.createElement('canvas');
    thumbnailCanvas.width = 40;
    thumbnailCanvas.height = 30;
    const thumbCtx = thumbnailCanvas.getContext('2d');
    
    // Draw white background
    thumbCtx.fillStyle = 'white';
    thumbCtx.fillRect(0, 0, 40, 30);
    
    // Draw layer content scaled down
    thumbCtx.drawImage(layer.canvas, 0, 0, 40, 30);
    
    return thumbnailCanvas.toDataURL();
}

function updateLayersList() {
    const layersList = document.getElementById('layers-list');
    layersList.innerHTML = '';
    
    layers.forEach((layer, index) => {
        const layerItem = document.createElement('div');
        layerItem.className = 'layer-item' + (index === activeLayerIndex ? ' active' : '');
        
        const thumbnail = document.createElement('canvas');
        thumbnail.className = 'layer-thumbnail';
        thumbnail.width = 40;
        thumbnail.height = 30;
        const thumbCtx = thumbnail.getContext('2d');
        thumbCtx.fillStyle = 'white';
        thumbCtx.fillRect(0, 0, 40, 30);
        thumbCtx.drawImage(layer.canvas, 0, 0, 40, 30);
        
        const layerInfo = document.createElement('div');
        layerInfo.className = 'layer-info';
        
        const layerName = document.createElement('div');
        layerName.className = 'layer-name';
        layerName.textContent = layer.name;
        layerName.addEventListener('dblclick', (e) => {
            e.stopPropagation();
            const input = document.createElement('input');
            input.type = 'text';
            input.value = layer.name;
            input.addEventListener('blur', () => {
                layer.name = input.value || layer.name;
                updateLayersList();
            });
            input.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') input.blur();
                if (e.key === 'Escape') {
                    input.value = layer.name;
                    input.blur();
                }
            });
            layerName.innerHTML = '';
            layerName.appendChild(input);
            input.focus();
            input.select();
        });
        
        layerInfo.appendChild(layerName);
        
        const layerActions = document.createElement('div');
        layerActions.className = 'layer-actions';
        
        const visibilityBtn = document.createElement('button');
        visibilityBtn.className = 'layer-visibility-btn' + (layer.visible ? ' visible' : '');
        visibilityBtn.textContent = layer.visible ? '👁️' : '👁️‍🗨️';
        visibilityBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            toggleLayerVisibility(index);
        });
        
        const moveBtns = document.createElement('div');
        moveBtns.className = 'layer-move-btns';
        
        const moveUpBtn = document.createElement('button');
        moveUpBtn.className = 'layer-move-btn';
        moveUpBtn.textContent = '▲';
        moveUpBtn.disabled = index === 0;
        moveUpBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            moveLayer(index, index - 1);
        });
        
        const moveDownBtn = document.createElement('button');
        moveDownBtn.className = 'layer-move-btn';
        moveDownBtn.textContent = '▼';
        moveDownBtn.disabled = index === layers.length - 1;
        moveDownBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            moveLayer(index, index + 1);
        });
        
        moveBtns.appendChild(moveUpBtn);
        moveBtns.appendChild(moveDownBtn);
        
        layerActions.appendChild(visibilityBtn);
        layerActions.appendChild(moveBtns);
        
        layerItem.appendChild(thumbnail);
        layerItem.appendChild(layerInfo);
        layerItem.appendChild(layerActions);
        
        layerItem.addEventListener('click', () => {
            setActiveLayer(index);
        });
        
        // Touch-friendly layer selection
        layerItem.addEventListener('touchend', (e) => {
            e.preventDefault();
            e.stopPropagation();
            setActiveLayer(index);
        }, { passive: false });
        
        layersList.appendChild(layerItem);
    });
    
    // Update button states
    document.getElementById('delete-layer-btn').disabled = layers.length <= 1;
    document.getElementById('merge-down-btn').disabled = activeLayerIndex >= layers.length - 1;
}

function updateLayerOpacityControl() {
    const layer = layers[activeLayerIndex];
    const opacitySlider = document.getElementById('layer-opacity');
    const opacityDisplay = document.getElementById('opacity-display');
    opacitySlider.value = layer.opacity * 100;
    opacityDisplay.textContent = Math.round(layer.opacity * 100) + '%';
}

// History Management Functions
function saveHistory() {
    // Remove any history steps after the current step
    if (historyStep < history.length - 1) {
        history = history.slice(0, historyStep + 1);
    }
    
    // Save current state of all layers
    const state = layers.map(layer => ({
        id: layer.id,
        name: layer.name,
        visible: layer.visible,
        opacity: layer.opacity,
        imageData: layer.ctx.getImageData(0, 0, canvas.width, canvas.height)
    }));
    
    history.push({
        layers: state,
        activeLayerIndex: activeLayerIndex
    });
    
    // Limit history size
    if (history.length > MAX_HISTORY) {
        history.shift();
    } else {
        historyStep++;
    }
    
    updateHistoryButtons();
}

function undo() {
    if (historyStep > 0) {
        initAudio();
        playSound('click');
        historyStep--;
        restoreHistory();
    }
}

function redo() {
    if (historyStep < history.length - 1) {
        initAudio();
        playSound('click');
        historyStep++;
        restoreHistory();
    }
}

function restoreHistory() {
    if (historyStep < 0 || historyStep >= history.length) return;
    
    const state = history[historyStep];
    
    // Restore layers
    layers = state.layers.map(layerState => {
        const layerCanvas = document.createElement('canvas');
        layerCanvas.width = canvas.width;
        layerCanvas.height = canvas.height;
        const layerCtx = layerCanvas.getContext('2d');
        layerCtx.putImageData(layerState.imageData, 0, 0);
        
        return {
            id: layerState.id,
            name: layerState.name,
            canvas: layerCanvas,
            ctx: layerCtx,
            visible: layerState.visible,
            opacity: layerState.opacity
        };
    });
    
    activeLayerIndex = state.activeLayerIndex;
    
    renderCanvas();
    updateLayersList();
    updateLayerOpacityControl();
    updateHistoryButtons();
}

function updateHistoryButtons() {
    const undoBtn = document.getElementById('undo-btn');
    const redoBtn = document.getElementById('redo-btn');
    
    if (undoBtn) {
        undoBtn.disabled = historyStep <= 0;
    }
    
    if (redoBtn) {
        redoBtn.disabled = historyStep >= history.length - 1;
    }
}

// Initialize layers
initializeLayers();

// Save initial state to history
saveHistory();

// Undo/Redo button event listeners
const undoBtn = document.getElementById('undo-btn');
const redoBtn = document.getElementById('redo-btn');
if (undoBtn) {
    undoBtn.addEventListener('click', undo);
}
if (redoBtn) {
    redoBtn.addEventListener('click', redo);
}

// Tool buttons
document.querySelectorAll('.tool-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playSound('click');
        document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
        
        // Clear any selection outlines when switching tools
        if (currentTool !== 'select-circle' && currentTool !== 'select-square' && currentTool !== 'paste') {
            renderCanvas(); // Re-render to clear selection outlines
        }
        
        updateToolUI();
        updateCursor();
    });
});

// Update UI based on selected tool
function updateToolUI() {
    const rotationSection = document.getElementById('rotation-section');
    
    if (currentTool === 'stamp') {
        // Show rotation section for stamp tool
        if (rotationSection) {
            rotationSection.style.display = 'block';
            updateRotationDisplay();
        }
    } else {
        // Hide rotation section for other tools
        if (rotationSection) {
            rotationSection.style.display = 'none';
        }
    }
}

// Update rotation angle display
function updateRotationDisplay() {
    const rotationAngle = document.getElementById('rotation-angle');
    if (rotationAngle) {
        rotationAngle.textContent = `${Math.round(stampRotation)}°`;
    }
}

// Reset stamp rotation
function resetRotation() {
    stampRotation = 0;
    updateRotationDisplay();
    updateCursor();
    initAudio();
    playSound('click');
}

// Reset rotation button
const resetRotationBtn = document.getElementById('reset-rotation-btn');
if (resetRotationBtn) {
    resetRotationBtn.addEventListener('click', resetRotation);
}

// Color buttons
document.querySelectorAll('.color-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        initAudio();
        playSound('click');
        document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentColor = btn.dataset.color;
        rainbowMode = false;
        if (currentTool === 'stamp') updateCursor();
    });
});

// Color picker (color wheel)
const colorPicker = document.getElementById('color-picker');
const colorHex = document.getElementById('color-hex');

function updateColorFromPicker(value) {
    currentColor = value;
    colorHex.textContent = value.toUpperCase();
    rainbowMode = false;
    document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
    if (currentTool === 'stamp') updateCursor();
}

if (colorPicker && colorHex) {
    colorPicker.addEventListener('input', (e) => {
        initAudio();
        updateColorFromPicker(e.target.value);
    });
    
    // Additional change event for iOS
    colorPicker.addEventListener('change', (e) => {
        initAudio();
        updateColorFromPicker(e.target.value);
    });
    
    // Improve iOS color picker opening
    colorPicker.addEventListener('click', (e) => {
        initAudio();
        // Force iOS to show color picker
        e.target.focus();
    });
}

// Brush size
const brushSizeSlider = document.getElementById('brush-size');
const sizeDisplay = document.getElementById('size-display');

function updateBrushSize(value) {
    brushSize = value;
    sizeDisplay.textContent = brushSize;
    if (currentTool === 'stamp') updateCursor();
}

brushSizeSlider.addEventListener('input', (e) => {
    updateBrushSize(e.target.value);
});

// Better touch handling for sliders on iOS
brushSizeSlider.addEventListener('touchmove', (e) => {
    e.stopPropagation(); // Prevent scroll while adjusting
}, { passive: false });

brushSizeSlider.addEventListener('change', (e) => {
    updateBrushSize(e.target.value);
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
    if (currentTool === 'stamp') updateCursor();
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
        if (currentTool === 'stamp') updateCursor();
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
    
    // Additional change event for iOS
    secondaryColorPicker.addEventListener('change', (e) => {
        initAudio();
        secondaryColor = e.target.value;
    });
    
    // Improve iOS color picker opening
    secondaryColorPicker.addEventListener('click', (e) => {
        initAudio();
        e.target.focus();
    });
}

// Selection action buttons
const copyBtn = document.getElementById('copy-btn');
const cutBtn = document.getElementById('cut-btn');
const pasteBtn = document.getElementById('paste-btn');

function handleCopy() {
    if (selectionData) {
        initAudio();
        playSound('click');
        // Copy the selection data and bounds to clipboard
        clipboard = {
            imageData: selectionData,
            type: selectionType,
            bounds: { ...selectionBounds }  // Create a copy of bounds object
        };
        pasteBtn.disabled = false;
        selectionData = null;
        selectionBounds = null;
        
        // Visual feedback for mobile
        showToast('✓ Copied to clipboard');
    }
}

function handleCut() {
    if (selectionData) {
        initAudio();
        playSound('click');
        // Copy the selection data and bounds to clipboard
        clipboard = {
            imageData: selectionData,
            type: selectionType,
            bounds: { ...selectionBounds }  // Create a copy of bounds object
        };
        pasteBtn.disabled = false;
        
        // Clear the selected area
        clearSelection();
        selectionData = null;
        selectionBounds = null;
        
        // Save history after cutting
        saveHistory();
        
        // Visual feedback for mobile
        showToast('✓ Cut to clipboard');
    }
}

function handlePaste() {
    if (clipboard) {
        initAudio();
        playSound('click');
        currentTool = 'paste';
        // Switch to paste mode
        showToast('Tap canvas to paste');
    }
}

// Show toast notification for mobile feedback
function showToast(message) {
    const existingToast = document.querySelector('.toast-notification');
    if (existingToast) {
        existingToast.remove();
    }
    
    const toast = document.createElement('div');
    toast.className = 'toast-notification';
    toast.textContent = message;
    document.body.appendChild(toast);
    
    // Animate in
    setTimeout(() => toast.classList.add('show'), 10);
    
    // Remove after 2 seconds
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 2000);
}

if (copyBtn) {
    copyBtn.addEventListener('click', handleCopy);
}

if (cutBtn) {
    cutBtn.addEventListener('click', handleCut);
}

if (pasteBtn) {
    pasteBtn.addEventListener('click', handlePaste);
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
        updateToolUI();
        updateCursor();
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
            // Update visual state
            btn.classList.toggle('active', rainbowMode);
            document.querySelector('[data-effect="sparkle"]').classList.remove('active');
            if (currentTool === 'stamp') updateCursor();
        } else if (effect === 'sparkle') {
            sparkleMode = !sparkleMode;
            rainbowMode = false;
            // Update visual state
            btn.classList.toggle('active', sparkleMode);
            document.querySelector('[data-effect="rainbow"]').classList.remove('active');
        }
    });
});

// Layer control event listeners
document.getElementById('add-layer-btn').addEventListener('click', addLayer);
document.getElementById('delete-layer-btn').addEventListener('click', deleteLayer);
document.getElementById('duplicate-layer-btn').addEventListener('click', duplicateLayer);
document.getElementById('merge-down-btn').addEventListener('click', mergeLayerDown);

// Layer panel toggle
document.getElementById('layer-toggle').addEventListener('click', () => {
    initAudio();
    playSound('click');
    const panel = document.querySelector('.layer-panel');
    panel.classList.toggle('collapsed');
});

// Layer opacity control
let opacityChangeTimeout;
const layerOpacitySlider = document.getElementById('layer-opacity');

function handleOpacityChange(value) {
    const opacity = value / 100;
    setLayerOpacity(opacity);
    document.getElementById('opacity-display').textContent = value + '%';
    
    // Save history after user stops adjusting (debounce)
    clearTimeout(opacityChangeTimeout);
    opacityChangeTimeout = setTimeout(() => {
        saveHistory();
    }, 500);
}

layerOpacitySlider.addEventListener('input', (e) => {
    handleOpacityChange(e.target.value);
});

// Better touch handling for opacity slider on iOS
layerOpacitySlider.addEventListener('touchmove', (e) => {
    e.stopPropagation(); // Prevent scroll while adjusting
}, { passive: false });

layerOpacitySlider.addEventListener('change', (e) => {
    handleOpacityChange(e.target.value);
});

// Save button - merge all layers
document.getElementById('save-btn').addEventListener('click', () => {
    initAudio();
    playSound('save');
    
    // Create a temporary canvas to merge all layers
    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = canvas.width;
    tempCanvas.height = canvas.height;
    const tempCtx = tempCanvas.getContext('2d');
    
    // Draw all visible layers
    for (let i = layers.length - 1; i >= 0; i--) {
        const layer = layers[i];
        if (layer.visible) {
            tempCtx.save();
            tempCtx.globalAlpha = layer.opacity;
            tempCtx.drawImage(layer.canvas, 0, 0);
            tempCtx.restore();
        }
    }
    
    // Create a temporary link element
    const link = document.createElement('a');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    link.download = `emojipix-${timestamp}.png`;
    
    // Convert merged canvas to PNG data URL
    link.href = tempCanvas.toDataURL('image/png');
    
    // Trigger download
    link.click();
    
    // Optional: Show a fun confirmation
    console.log('🎨 Masterpiece saved!');
});

// Clear button
document.getElementById('clear-btn').addEventListener('click', () => {
    initAudio();
    if (confirm('🎨 Clear active layer?')) {
        playSound('clear');
        // Fun Kid Pix-style clear animation
        clearCanvasWithAnimation();
    }
});

function clearCanvasWithAnimation() {
    const activeCtx = getActiveContext();
    let y = 0;
    const clearInterval = setInterval(() => {
        activeCtx.clearRect(0, y, canvas.width, 20);
        renderCanvas();
        y += 20;
        if (y >= canvas.height) {
            clearInterval(clearInterval);
            activeCtx.clearRect(0, 0, canvas.width, canvas.height);
            renderCanvas();
            updateLayersList();
            saveHistory();
        }
    }, 20);
}

// Mouse events
canvas.addEventListener('mousedown', startDrawing);
canvas.addEventListener('mousemove', draw);
canvas.addEventListener('mouseup', stopDrawing);
canvas.addEventListener('mouseout', (e) => {
    if (currentTool === 'circle' || currentTool === 'square' || currentTool === 'triangle' || 
        currentTool === 'star' || currentTool === 'line' || 
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
let lastTouchX = 0;
let lastTouchY = 0;

canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    initAudio();
    const touch = e.touches[0];
    const rect = canvas.getBoundingClientRect();
    lastTouchX = touch.clientX;
    lastTouchY = touch.clientY;
    
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
    lastTouchX = touch.clientX;
    lastTouchY = touch.clientY;
    
    const mouseEvent = new MouseEvent('mousemove', {
        clientX: touch.clientX,
        clientY: touch.clientY,
        bubbles: true
    });
    canvas.dispatchEvent(mouseEvent);
}, { passive: false });

canvas.addEventListener('touchend', (e) => {
    e.preventDefault();
    // Use last known touch position for touchend
    const mouseEvent = new MouseEvent('mouseup', {
        clientX: lastTouchX,
        clientY: lastTouchY,
        bubbles: true
    });
    canvas.dispatchEvent(mouseEvent);
}, { passive: false });

canvas.addEventListener('touchcancel', (e) => {
    e.preventDefault();
    const mouseEvent = new MouseEvent('mouseup', {
        clientX: lastTouchX,
        clientY: lastTouchY,
        bubbles: true
    });
    canvas.dispatchEvent(mouseEvent);
}, { passive: false });

// Mouse wheel for stamp rotation
canvas.addEventListener('wheel', (e) => {
    if (currentTool === 'stamp') {
        e.preventDefault();
        
        // Adjust rotation based on wheel delta
        const rotationStep = 15; // degrees per wheel notch
        if (e.deltaY < 0) {
            // Scroll up - rotate counter-clockwise
            stampRotation -= rotationStep;
        } else {
            // Scroll down - rotate clockwise
            stampRotation += rotationStep;
        }
        
        // Normalize rotation to 0-360 range
        stampRotation = ((stampRotation % 360) + 360) % 360;
        
        // Update UI and cursor to show new rotation
        updateRotationDisplay();
        updateCursor();
        
        // Play a subtle sound
        initAudio();
        playSound('custom', 400 + (stampRotation / 360) * 200, 0.05);
    }
}, { passive: false });

// Two-finger rotation for stamp on mobile (iOS)
let lastTwoFingerAngle = null;

canvas.addEventListener('touchstart', (e) => {
    if (e.touches.length === 2 && currentTool === 'stamp') {
        const touch1 = e.touches[0];
        const touch2 = e.touches[1];
        lastTwoFingerAngle = Math.atan2(
            touch2.clientY - touch1.clientY,
            touch2.clientX - touch1.clientX
        ) * 180 / Math.PI;
    }
}, { passive: true });

canvas.addEventListener('touchmove', (e) => {
    if (e.touches.length === 2 && currentTool === 'stamp') {
        e.preventDefault();
        const touch1 = e.touches[0];
        const touch2 = e.touches[1];
        const currentAngle = Math.atan2(
            touch2.clientY - touch1.clientY,
            touch2.clientX - touch1.clientX
        ) * 180 / Math.PI;
        
        if (lastTwoFingerAngle !== null) {
            let angleDiff = currentAngle - lastTwoFingerAngle;
            
            // Normalize angle difference to -180 to 180
            if (angleDiff > 180) angleDiff -= 360;
            if (angleDiff < -180) angleDiff += 360;
            
            stampRotation += angleDiff;
            stampRotation = ((stampRotation % 360) + 360) % 360;
            
            updateRotationDisplay();
            updateCursor();
        }
        
        lastTwoFingerAngle = currentAngle;
    }
}, { passive: false });

canvas.addEventListener('touchend', (e) => {
    if (e.touches.length < 2) {
        lastTwoFingerAngle = null;
    }
}, { passive: true });

function startDrawing(e) {
    initAudio();
    isDrawing = true;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    if (currentTool === 'fill') {
        playSound('fill');
        floodFill(x, y, hexToRgb(currentColor));
        saveHistory();
        isDrawing = false;
    } else if (currentTool === 'stamp') {
        playSound('stamp');
        stampEmoji(x, y);
        saveHistory();
        isDrawing = false;
    } else if (currentTool === 'paste' && clipboard) {
        playSound('stamp');
        pasteClipboard(x, y);
        saveHistory();
        isDrawing = false;
    } else if (currentTool === 'circle' || currentTool === 'square' || currentTool === 'triangle' || 
               currentTool === 'star' || currentTool === 'line' || 
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
        } else if (currentTool === 'triangle') {
            drawTriangle(shapeStartX, shapeStartY, x, y);
            playSound('stamp');
        } else if (currentTool === 'star') {
            drawStar(shapeStartX, shapeStartY, x, y);
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
    const activeCtx = getActiveContext();
    activeCtx.beginPath();
    
    // Update layer thumbnail and render
    renderCanvas();
    updateLayersList();
    
    // Save to history after drawing
    saveHistory();
}

let lastSoundTime = 0;
const soundThrottle = 50; // milliseconds between sounds

function drawPencil(x, y) {
    const activeCtx = getActiveContext();
    activeCtx.lineCap = 'round';
    activeCtx.lineJoin = 'round';
    activeCtx.lineWidth = brushSize;
    
    if (rainbowMode) {
        rainbowHue = (rainbowHue + 2) % 360;
        activeCtx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        activeCtx.strokeStyle = currentColor;
    }
    
    activeCtx.lineTo(x, y);
    activeCtx.stroke();
    activeCtx.beginPath();
    activeCtx.moveTo(x, y);
    
    // Render canvas continuously while drawing
    renderCanvas();
    
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
    const activeCtx = getActiveContext();
    activeCtx.lineCap = 'round';
    activeCtx.lineJoin = 'round';
    activeCtx.lineWidth = brushSize * 2;
    activeCtx.globalCompositeOperation = 'destination-out';
    
    activeCtx.lineTo(x, y);
    activeCtx.stroke();
    activeCtx.beginPath();
    activeCtx.moveTo(x, y);
    
    activeCtx.globalCompositeOperation = 'source-over';
    
    // Render canvas continuously while drawing
    renderCanvas();
    
    // Play sound occasionally
    const now = Date.now();
    if (now - lastSoundTime > soundThrottle) {
        playSound('eraser');
        lastSoundTime = now;
    }
}

function drawSpray(x, y) {
    const activeCtx = getActiveContext();
    const density = brushSize * 2;
    const radius = brushSize * 3;
    
    for (let i = 0; i < density; i++) {
        const offsetX = (Math.random() - 0.5) * radius;
        const offsetY = (Math.random() - 0.5) * radius;
        
        if (rainbowMode) {
            rainbowHue = (rainbowHue + 1) % 360;
            activeCtx.fillStyle = `hsl(${rainbowHue}, 100%, 50%)`;
        } else {
            activeCtx.fillStyle = currentColor;
        }
        
        activeCtx.fillRect(x + offsetX, y + offsetY, 2, 2);
    }
    
    // Render canvas continuously while drawing
    renderCanvas();
    
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
    const activeCtx = getActiveContext();
    const size = brushSize * 10;
    
    // Check if it's a text character (letter, number, or common punctuation)
    const isTextCharacter = /^[A-Za-z0-9!?&@#$%*+\-=/]$/.test(selectedEmoji);
    const isLetter = /^[A-Za-z]$/.test(selectedEmoji);
    
    // Apply case transformation to letters
    let charToStamp = selectedEmoji;
    if (isLetter) {
        charToStamp = textCase === 'upper' ? selectedEmoji.toUpperCase() : selectedEmoji.toLowerCase();
    }
    
    // Save context state
    activeCtx.save();
    
    // Apply rotation
    activeCtx.translate(x, y);
    activeCtx.rotate((stampRotation * Math.PI) / 180);
    activeCtx.translate(-x, -y);
    
    if (isTextCharacter) {
        // Use selected font for text characters
        activeCtx.font = `bold ${size}px "${selectedFont}", Arial, sans-serif`;
    } else {
        // Use default for emojis
        activeCtx.font = `${size}px Arial`;
    }
    
    activeCtx.textAlign = 'center';
    activeCtx.textBaseline = 'middle';
    
    // Apply current color to text characters
    if (isTextCharacter) {
        if (rainbowMode) {
            rainbowHue = (rainbowHue + 15) % 360;
            activeCtx.fillStyle = `hsl(${rainbowHue}, 100%, 50%)`;
        } else {
            activeCtx.fillStyle = currentColor;
        }
    } else {
        // Emojis use default rendering
        activeCtx.fillStyle = '#000000';
    }
    
    activeCtx.fillText(charToStamp, x, y);
    
    // Restore context state
    activeCtx.restore();
    
    // Add sparkle effect
    if (sparkleMode) {
        addSparkles(x, y);
        addSparkles(x - size/3, y - size/3);
        addSparkles(x + size/3, y - size/3);
        addSparkles(x - size/3, y + size/3);
        addSparkles(x + size/3, y + size/3);
    }
    
    // Render after stamping
    renderCanvas();
    updateLayersList();
    
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
    const activeCtx = getActiveContext();
    const sparkleCount = 3;
    const sparkleRadius = brushSize * 2;
    
    for (let i = 0; i < sparkleCount; i++) {
        const sparkleX = x + (Math.random() - 0.5) * sparkleRadius;
        const sparkleY = y + (Math.random() - 0.5) * sparkleRadius;
        const sparkleSize = Math.random() * 3 + 1;
        
        activeCtx.fillStyle = '#FFFF00';
        activeCtx.beginPath();
        activeCtx.arc(sparkleX, sparkleY, sparkleSize, 0, Math.PI * 2);
        activeCtx.fill();
        
        // Draw star points
        activeCtx.fillStyle = '#FFFFFF';
        activeCtx.fillRect(sparkleX - sparkleSize/2, sparkleY, sparkleSize, 1);
        activeCtx.fillRect(sparkleX, sparkleY - sparkleSize/2, 1, sparkleSize);
    }
}

function createPattern() {
    // Handle rainbow mode for solid fills
    if (fillPattern === 'solid') {
        if (rainbowMode) {
            rainbowHue = (rainbowHue + 10) % 360;
            return `hsl(${rainbowHue}, 100%, 50%)`;
        }
        return currentColor;
    }
    
    if (fillPattern === 'transparent') {
        return null; // Return null for transparent
    }
    
    const patternCanvas = document.createElement('canvas');
    const patternCtx = patternCanvas.getContext('2d');
    
    // Apply rainbow to primary color if rainbow mode is active
    let color1 = currentColor;
    if (rainbowMode) {
        rainbowHue = (rainbowHue + 10) % 360;
        color1 = `hsl(${rainbowHue}, 100%, 50%)`;
    }
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
    
    const activeCtx = getActiveContext();
    return activeCtx.createPattern(patternCanvas, 'repeat');
}

function drawCircle(startX, startY, endX, endY) {
    const activeCtx = getActiveContext();
    const radius = Math.sqrt(Math.pow(endX - startX, 2) + Math.pow(endY - startY, 2));
    
    activeCtx.beginPath();
    activeCtx.arc(startX, startY, radius, 0, Math.PI * 2);
    
    const fillStyle = createPattern();
    if (fillStyle !== null) {
        activeCtx.fillStyle = fillStyle;
        activeCtx.fill();
    }
    
    // Apply rainbow mode to stroke
    if (rainbowMode) {
        rainbowHue = (rainbowHue + 10) % 360;
        activeCtx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        activeCtx.strokeStyle = currentColor;
    }
    activeCtx.lineWidth = Math.max(brushSize / 2, 2);
    activeCtx.stroke();
    
    if (sparkleMode) {
        addSparkles(startX, startY);
        // Add sparkles around the circle
        for (let i = 0; i < 8; i++) {
            const angle = (Math.PI * 2 * i) / 8;
            const sparkleX = startX + Math.cos(angle) * radius;
            const sparkleY = startY + Math.sin(angle) * radius;
            addSparkles(sparkleX, sparkleY);
        }
    }
    
    renderCanvas();
    updateLayersList();
}

function drawSquare(startX, startY, endX, endY) {
    const activeCtx = getActiveContext();
    const width = endX - startX;
    const height = endY - startY;
    
    activeCtx.beginPath();
    activeCtx.rect(startX, startY, width, height);
    
    const fillStyle = createPattern();
    if (fillStyle !== null) {
        activeCtx.fillStyle = fillStyle;
        activeCtx.fill();
    }
    
    // Apply rainbow mode to stroke
    if (rainbowMode) {
        rainbowHue = (rainbowHue + 10) % 360;
        activeCtx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        activeCtx.strokeStyle = currentColor;
    }
    activeCtx.lineWidth = Math.max(brushSize / 2, 2);
    activeCtx.stroke();
    
    if (sparkleMode) {
        addSparkles(startX + width/2, startY + height/2);
        // Add sparkles at corners
        addSparkles(startX, startY);
        addSparkles(endX, startY);
        addSparkles(startX, endY);
        addSparkles(endX, endY);
    }
    
    renderCanvas();
    updateLayersList();
}

function drawTriangle(startX, startY, endX, endY) {
    const activeCtx = getActiveContext();
    const width = endX - startX;
    const height = endY - startY;
    
    // Calculate triangle points (equilateral-ish triangle)
    const topX = startX + width / 2;
    const topY = startY;
    const bottomLeftX = startX;
    const bottomLeftY = endY;
    const bottomRightX = endX;
    const bottomRightY = endY;
    
    activeCtx.beginPath();
    activeCtx.moveTo(topX, topY);
    activeCtx.lineTo(bottomLeftX, bottomLeftY);
    activeCtx.lineTo(bottomRightX, bottomRightY);
    activeCtx.closePath();
    
    const fillStyle = createPattern();
    if (fillStyle !== null) {
        activeCtx.fillStyle = fillStyle;
        activeCtx.fill();
    }
    
    // Apply rainbow mode to stroke
    if (rainbowMode) {
        rainbowHue = (rainbowHue + 10) % 360;
        activeCtx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        activeCtx.strokeStyle = currentColor;
    }
    activeCtx.lineWidth = Math.max(brushSize / 2, 2);
    activeCtx.stroke();
    
    if (sparkleMode) {
        // Add sparkles at triangle points
        addSparkles(topX, topY);
        addSparkles(bottomLeftX, bottomLeftY);
        addSparkles(bottomRightX, bottomRightY);
        addSparkles(startX + width/2, startY + height/2);
    }
    
    renderCanvas();
    updateLayersList();
}

function drawStar(startX, startY, endX, endY) {
    const activeCtx = getActiveContext();
    const centerX = (startX + endX) / 2;
    const centerY = (startY + endY) / 2;
    const radius = Math.sqrt(Math.pow(endX - startX, 2) + Math.pow(endY - startY, 2)) / 2;
    const innerRadius = radius * 0.4; // Inner radius for star points
    const points = 5;
    
    activeCtx.beginPath();
    for (let i = 0; i < points * 2; i++) {
        const angle = (i * Math.PI) / points - Math.PI / 2;
        const r = i % 2 === 0 ? radius : innerRadius;
        const x = centerX + r * Math.cos(angle);
        const y = centerY + r * Math.sin(angle);
        
        if (i === 0) {
            activeCtx.moveTo(x, y);
        } else {
            activeCtx.lineTo(x, y);
        }
    }
    activeCtx.closePath();
    
    const fillStyle = createPattern();
    if (fillStyle !== null) {
        activeCtx.fillStyle = fillStyle;
        activeCtx.fill();
    }
    
    // Apply rainbow mode to stroke
    if (rainbowMode) {
        rainbowHue = (rainbowHue + 10) % 360;
        activeCtx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        activeCtx.strokeStyle = currentColor;
    }
    activeCtx.lineWidth = Math.max(brushSize / 2, 2);
    activeCtx.stroke();
    
    if (sparkleMode) {
        // Add sparkles at star points
        for (let i = 0; i < points; i++) {
            const angle = (i * 2 * Math.PI) / points - Math.PI / 2;
            const x = centerX + radius * Math.cos(angle);
            const y = centerY + radius * Math.sin(angle);
            addSparkles(x, y);
        }
        addSparkles(centerX, centerY);
    }
    
    renderCanvas();
    updateLayersList();
}

function drawLine(startX, startY, endX, endY) {
    const activeCtx = getActiveContext();
    activeCtx.beginPath();
    activeCtx.moveTo(startX, startY);
    activeCtx.lineTo(endX, endY);
    
    if (rainbowMode) {
        activeCtx.strokeStyle = `hsl(${rainbowHue}, 100%, 50%)`;
    } else {
        activeCtx.strokeStyle = currentColor;
    }
    
    activeCtx.lineWidth = brushSize;
    activeCtx.lineCap = 'round';
    activeCtx.stroke();
    
    if (sparkleMode) {
        addSparkles((startX + endX) / 2, (startY + endY) / 2);
    }
    
    renderCanvas();
    updateLayersList();
}

function selectCircle(startX, startY, endX, endY) {
    const radius = Math.sqrt(Math.pow(endX - startX, 2) + Math.pow(endY - startY, 2));
    
    if (radius < 5) return; // Ignore very small selections
    
    // Get the bounding box
    const left = Math.max(0, Math.floor(startX - radius));
    const top = Math.max(0, Math.floor(startY - radius));
    const width = Math.min(canvas.width - left, Math.ceil(radius * 2));
    const height = Math.min(canvas.height - top, Math.ceil(radius * 2));
    
    // Get the image data from the active layer
    const activeCtx = getActiveContext();
    const imageData = activeCtx.getImageData(left, top, width, height);
    
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
    
    // Clear previous selection outline and draw new one
    renderCanvas();
    ctx.save();
    ctx.strokeStyle = '#667eea';
    ctx.lineWidth = 3; // Thicker for better mobile visibility
    ctx.setLineDash([8, 4]); // Larger dashes for mobile
    ctx.beginPath();
    ctx.arc(startX, startY, radius, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();
    
    // Visual feedback for mobile
    showToast('Selection created - Copy or Cut');
}

function selectSquare(startX, startY, endX, endY) {
    const left = Math.min(startX, endX);
    const top = Math.min(startY, endY);
    const width = Math.abs(endX - startX);
    const height = Math.abs(endY - startY);
    
    if (width < 5 || height < 5) return; // Ignore very small selections
    
    // Get the image data from the active layer
    const activeCtx = getActiveContext();
    const imageData = activeCtx.getImageData(left, top, width, height);
    
    selectionData = imageData;
    selectionType = 'square';
    selectionBounds = { left: left, top: top, width: width, height: height };
    
    // Clear previous selection outline and draw new one
    renderCanvas();
    ctx.save();
    ctx.strokeStyle = '#667eea';
    ctx.lineWidth = 3; // Thicker for better mobile visibility
    ctx.setLineDash([8, 4]); // Larger dashes for mobile
    ctx.strokeRect(left, top, width, height);
    ctx.restore();
    
    // Visual feedback for mobile
    showToast('Selection created - Copy or Cut');
}

function clearSelection() {
    if (!selectionBounds) return;
    
    const activeCtx = getActiveContext();
    
    // Clear the selected area on the active layer (make it transparent)
    activeCtx.save();
    activeCtx.globalCompositeOperation = 'destination-out';
    
    if (selectionType === 'circle') {
        activeCtx.beginPath();
        activeCtx.arc(selectionBounds.x, selectionBounds.y, selectionBounds.radius, 0, Math.PI * 2);
        activeCtx.fill();
    } else if (selectionType === 'square') {
        activeCtx.fillRect(selectionBounds.left, selectionBounds.top, selectionBounds.width, selectionBounds.height);
    }
    
    activeCtx.restore();
    
    // Re-render the canvas to show the changes
    renderCanvas();
    updateLayersList();
}

function pasteClipboard(x, y) {
    if (!clipboard) return;
    
    const activeCtx = getActiveContext();
    const imageData = clipboard.imageData;
    const bounds = clipboard.bounds;
    
    // Calculate paste position (centered on click)
    let pasteX = x - bounds.width / 2;
    let pasteY = y - bounds.height / 2;
    
    // Put the image data at the new position on the active layer
    activeCtx.putImageData(imageData, pasteX, pasteY);
    
    // Re-render the canvas to show the changes
    renderCanvas();
    updateLayersList();
    
    if (sparkleMode) {
        addSparkles(x, y);
    }
}

function floodFill(startX, startY, fillColor) {
    const activeCtx = getActiveContext();
    const imageData = activeCtx.getImageData(0, 0, canvas.width, canvas.height);
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
    activeCtx.putImageData(imageData, 0, 0);
    
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
    const finalImageData = activeCtx.getImageData(0, 0, canvas.width, canvas.height);
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
    
    activeCtx.putImageData(finalImageData, 0, 0);
    
    // Add sparkle effect if enabled
    if (sparkleMode) {
        // Add sparkles at the click point
        addSparkles(startX, startY);
        
        // Add sparkles at random points within the filled area
        const sparkleCount = Math.min(10, Math.floor(visited.size / 100));
        const visitedArray = Array.from(visited);
        for (let i = 0; i < sparkleCount; i++) {
            const randomKey = visitedArray[Math.floor(Math.random() * visitedArray.length)];
            const [x, y] = randomKey.split(',').map(Number);
            addSparkles(x, y);
        }
    }
    
    renderCanvas();
    updateLayersList();
}

function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : { r: 0, g: 0, b: 0 };
}

// Function to update cursor based on tool and emoji
function updateCursor() {
    const cursorMap = {
        'pencil': 'crosshair',
        'eraser': 'cell',
        'line': 'crosshair',
        'circle': 'crosshair',
        'square': 'crosshair',
        'triangle': 'crosshair',
        'star': 'crosshair',
        'fill': 'cell',
        'spray': 'crosshair',
        'select-circle': 'crosshair',
        'select-square': 'crosshair',
        'paste': 'copy'
    };
    
    if (currentTool === 'stamp') {
        // Create a custom emoji cursor matching the actual stamp size
        const actualSize = brushSize * 10; // Match the size in stampEmoji()
        const cursorSize = Math.min(actualSize, 128); // Cap at 128px for cursor display
        
        const cursorCanvas = document.createElement('canvas');
        cursorCanvas.width = cursorSize;
        cursorCanvas.height = cursorSize;
        const cursorCtx = cursorCanvas.getContext('2d');
        
        // Check if it's a text character
        const isTextCharacter = /^[A-Za-z0-9!?&@#$%*+\-=/]$/.test(selectedEmoji);
        const isLetter = /^[A-Za-z]$/.test(selectedEmoji);
        
        // Apply case transformation to letters
        let charToDraw = selectedEmoji;
        if (isLetter) {
            charToDraw = textCase === 'upper' ? selectedEmoji.toUpperCase() : selectedEmoji.toLowerCase();
        }
        
        // Apply rotation to cursor
        cursorCtx.save();
        cursorCtx.translate(cursorSize / 2, cursorSize / 2);
        cursorCtx.rotate((stampRotation * Math.PI) / 180);
        cursorCtx.translate(-cursorSize / 2, -cursorSize / 2);
        
        // Set font based on character type - matching stampEmoji() function
        if (isTextCharacter) {
            cursorCtx.font = `bold ${cursorSize}px "${selectedFont}", Arial, sans-serif`;
        } else {
            cursorCtx.font = `${cursorSize}px Arial`;
        }
        
        cursorCtx.textAlign = 'center';
        cursorCtx.textBaseline = 'middle';
        
        // Apply color to text characters
        if (isTextCharacter) {
            if (rainbowMode) {
                cursorCtx.fillStyle = `hsl(${rainbowHue}, 100%, 50%)`;
            } else {
                cursorCtx.fillStyle = currentColor;
            }
        } else {
            cursorCtx.fillStyle = '#000000';
        }
        
        // Draw the emoji/character
        cursorCtx.fillText(charToDraw, cursorSize / 2, cursorSize / 2);
        
        cursorCtx.restore();
        
        // Convert to data URL and set as cursor
        const dataURL = cursorCanvas.toDataURL();
        canvas.style.cursor = `url('${dataURL}') ${cursorSize / 2} ${cursorSize / 2}, auto`;
    } else {
        // Use standard cursor for other tools
        canvas.style.cursor = cursorMap[currentTool] || 'crosshair';
    }
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

// Prevent iOS double-tap zoom on buttons and improve touch handling
const buttons = document.querySelectorAll('button');
buttons.forEach(button => {
    let touchStartTime;
    button.addEventListener('touchstart', (e) => {
        touchStartTime = Date.now();
    }, { passive: true });
    
    button.addEventListener('touchend', (e) => {
        e.preventDefault();
        const touchDuration = Date.now() - touchStartTime;
        // Only trigger click if it was a quick tap (not a long press or scroll)
        if (touchDuration < 500) {
            button.click();
        }
    }, { passive: false });
});

// Special handling for color inputs on iOS
const colorInputs = document.querySelectorAll('input[type="color"]');
colorInputs.forEach(input => {
    // Ensure color picker works on iOS
    input.addEventListener('touchend', (e) => {
        e.stopPropagation();
    }, { passive: true });
    
    // Force iOS to open color picker
    input.addEventListener('focus', () => {
        input.click();
    });
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

// Initialize cursor
updateCursor();

// Start with layer panel collapsed on mobile for more canvas space
if (window.innerWidth <= 768) {
    const layerPanel = document.querySelector('.layer-panel');
    if (layerPanel) {
        layerPanel.classList.add('collapsed');
    }
}

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    // Ignore shortcuts if user is typing in an input field
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') {
        return;
    }
    
    // Ctrl+Z or Cmd+Z for undo
    if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
        e.preventDefault();
        undo();
    }
    // Ctrl+Shift+Z or Cmd+Shift+Z or Ctrl+Y for redo
    else if (((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'z') || 
             (e.ctrlKey && e.key === 'y')) {
        e.preventDefault();
        redo();
    }
    // Number keys for tool selection (without modifiers)
    else if (!e.ctrlKey && !e.metaKey && !e.shiftKey && !e.altKey) {
        let toolToSelect = null;
        
        switch(e.key) {
            case '1':
                toolToSelect = 'pencil';
                break;
            case '2':
                toolToSelect = 'line';
                break;
            case '3':
                toolToSelect = 'eraser';
                break;
            case '4':
                toolToSelect = 'fill';
                break;
            case '5':
                toolToSelect = 'spray';
                break;
            case '6':
                toolToSelect = 'circle';
                break;
            case '7':
                toolToSelect = 'square';
                break;
            case '8':
                toolToSelect = 'triangle';
                break;
            case '9':
                toolToSelect = 'star';
                break;
            case '0':
                toolToSelect = 'stamp';
                break;
            case '[':
            case '{':
                toolToSelect = 'select-circle';
                break;
            case ']':
            case '}':
                toolToSelect = 'select-square';
                break;
            case 'r':
            case 'R':
                // Reset rotation when stamp tool is active
                if (currentTool === 'stamp') {
                    e.preventDefault();
                    resetRotation();
                }
                return;
        }
        
        if (toolToSelect) {
            e.preventDefault();
            initAudio();
            playSound('click');
            
            // Update active tool button
            document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
            const toolButton = document.querySelector(`[data-tool="${toolToSelect}"]`);
            if (toolButton) {
                toolButton.classList.add('active');
                currentTool = toolToSelect;
                updateToolUI();
                updateCursor();
            }
        }
    }
});

console.log('🎨 EmojiPix loaded! Have fun drawing!');

