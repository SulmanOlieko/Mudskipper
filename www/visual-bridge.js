let cm6View = null;
let currentMode = 'source'; // 'source' | 'visual'
let activeFileNameOriginal = '';

/**
 * Update the visual editor toggle buttons active/disabled states
 */
window.updateToggleState = function(filename) {
    if (!filename) return;
    activeFileNameOriginal = filename;
    const isTex = filename.toLowerCase().endsWith('.tex');
    const visualBtn = document.getElementById("btn-visual-mode");
    const sourceBtn = document.getElementById("btn-source-mode");
    
    if (visualBtn) {
        if (isTex) {
            visualBtn.classList.remove("disabled");
            visualBtn.title = "Switch to Visual Editor";
        } else {
            visualBtn.classList.add("disabled");
            visualBtn.title = "Visual Editor only available for .tex files";
            // If we are currently in visual mode, we MUST switch back to source
            if (currentMode === 'visual') {
                window.setEditorMode('source');
            }
        }
    }
    
    // Update active class based on currentMode
    if (visualBtn && sourceBtn) {
        if (currentMode === 'visual' && isTex) {
            visualBtn.classList.add("active");
            sourceBtn.classList.remove("active");
            visualBtn.setAttribute("aria-selected", "true");
            sourceBtn.setAttribute("aria-selected", "false");
        } else {
            sourceBtn.classList.add("active");
            visualBtn.classList.remove("active");
            sourceBtn.setAttribute("aria-selected", "true");
            visualBtn.setAttribute("aria-selected", "false");
            currentMode = 'source'; // Force state consistency
        }
    }
};

/**
 * Set the editor mode (source or visual)
 */
window.setEditorMode = function(mode) {
    const isTex = activeFileNameOriginal.toLowerCase().endsWith('.tex');
    if (mode === 'visual' && !isTex) return; // Guard clause
    
    currentMode = mode;
    
    const aceWrapper = document.getElementById("sourceEditor");
    const visualWrapper = document.getElementById("visualEditorContainer");
    
    if (window.ace) {
        const aceEd = ace.edit("sourceEditor");
        if (currentMode === 'visual') {
            const content = aceEd.getValue();
            aceWrapper.style.display = "none";
            visualWrapper.style.display = "block";
            
            if (!cm6View && window.MudskipperVisualEditor) {
                cm6View = window.MudskipperVisualEditor.initVisualEditor(
                    visualWrapper, 
                    content, 
                    (newDoc) => {
                        // Update ace silently (without triggering loops ideally)
                        const cursor = aceEd.getCursorPosition();
                        aceEd.session.setValue(newDoc);
                        aceEd.moveCursorToPosition(cursor);
                    }
                );
                cm6View.dom.style.height = "100%";
            } else if (cm6View) {
                window.MudskipperVisualEditor.setEditorContent(cm6View, content);
            }
        } else {
            visualWrapper.style.display = "none";
            aceWrapper.style.display = "block";
            if (cm6View) {
                const content = cm6View.state.doc.toString();
                const cursor = aceEd.getCursorPosition();
                aceEd.session.setValue(content);
                aceEd.moveCursorToPosition(cursor);
            }
        }
    }
    
    window.updateToggleState(activeFileNameOriginal);
};

// Compatibility shim for anything calling the old toggle function
window.toggleEditorMode = function() {
    window.setEditorMode(currentMode === 'source' ? 'visual' : 'source');
};

// --- INTERCEPT FILE LOADING ---
// We need to know the filename to update the toggle state.
// We intercept Shiny's cmdSafeLoadFile handler or listen to updateStatus.
(function() {
    const originalHandler = Shiny.addCustomMessageHandler;
    // Intercept existing handlers if already registered
    // Actually, it's easier to just register our own listener that runs alongside
    
    // We poll for updateStatus changes or similar
    setInterval(() => {
        const statusBar = document.getElementById('statusBar');
        if (statusBar) {
            //statusBar contains filename, often in a span with title or similar
            // But a better way is to listen for the fileClick input change or help from the server
            // For now, we'll try to extract from #statusBar text if possible, 
            // but let's look for a cleaner hook.
        }
    }, 1000);

    // Better: Hook into Shiny.addCustomMessageHandler to catch 'cmdSafeLoadFile'
    const origAddCustomMessageHandler = Shiny.addCustomMessageHandler;
    Shiny.addCustomMessageHandler = function(type, handler) {
        if (type === 'cmdSafeLoadFile' || type === 'updateStatus') {
            const wrappedHandler = function(msg) {
                // For updateStatus, msg is the filename (html)
                if (type === 'updateStatus') {
                    const cleanName = msg.replace(/<[^>]*>/g, '').replace(/\*/g, '').trim();
                    if (cleanName && cleanName !== activeFileNameOriginal) {
                        window.updateToggleState(cleanName);
                    }
                }
                
                // For cmdSafeLoadFile, msg has {content, mode}
                if (type === 'cmdSafeLoadFile' && currentMode === 'visual' && cm6View) {
                    // Update the visual editor content if it exists and we're in visual mode
                    if (window.MudskipperVisualEditor) {
                        window.MudskipperVisualEditor.setEditorContent(cm6View, msg.content);
                    }
                }
                
                handler(msg);
            };
            return origAddCustomMessageHandler.call(Shiny, type, wrappedHandler);
        }
        return origAddCustomMessageHandler.call(Shiny, type, handler);
    };
})();

