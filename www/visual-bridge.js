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
            if (currentMode === 'visual') {
                window.setEditorMode('source');
            }
        }
    }
    
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
            currentMode = 'source'; 
        }
    }
};

/**
 * Set the editor mode (source or visual)
 */
window.setEditorMode = function(mode) {
    const isTex = activeFileNameOriginal.toLowerCase().endsWith('.tex');
    if (mode === 'visual' && !isTex) return;
    
    currentMode = mode;
    
    const aceWrapper = document.getElementById("sourceEditor");
    const visualWrapper = document.getElementById("visualEditorContainer");
    
    if (window.ace) {
        const aceEd = ace.edit("sourceEditor");
        
        // --- MONKEY PATCH ACE TO SYNC WITH VISUAL EDITOR ---
        if (!aceEd._originalGetValue) {
            aceEd._originalGetValue = aceEd.getValue.bind(aceEd);
            aceEd.getValue = function() {
                if (currentMode === 'visual' && cm6View) {
                    return cm6View.state.doc.toString();
                }
                return aceEd._originalGetValue();
            };
        }

        if (currentMode === 'visual') {
            const content = aceEd._originalGetValue();
            const aceCursor = aceEd.getCursorPosition();
            
            aceWrapper.style.display = "none";
            visualWrapper.style.display = "block";
            
            if (!cm6View && window.MudskipperVisualEditor) {
                cm6View = window.MudskipperVisualEditor.initVisualEditor(
                    visualWrapper, 
                    content, 
                    (newDoc) => {
                        // Notify Shiny that content changed without heavy Ace updates
                        if (aceEd.session && aceEd.session._emit) {
                            aceEd.session._emit('change', { action: 'insert', start: {row:0, column:0}, end: {row:0, column:0}, lines: [] });
                        } else if (aceEd.session && aceEd.session._signal) {
                            aceEd.session._signal('change', { action: 'insert', start: {row:0, column:0}, end: {row:0, column:0}, lines: [] });
                        }
                    }
                );
                cm6View.dom.style.height = "100%";
                window.MudskipperVisualEditor.setCursorPosition(cm6View, aceCursor.row, aceCursor.column);
            } else if (cm6View) {
                window.MudskipperVisualEditor.setEditorContent(cm6View, content);
                window.MudskipperVisualEditor.setCursorPosition(cm6View, aceCursor.row, aceCursor.column);
            }
            
            // --- TEMPORARILY DISABLE ACE FEATURES ---
            if (window.disableMinimap) window.disableMinimap();
            if (window.stickyScrollInstance) window.stickyScrollInstance.disable();
            if (window.MathPreviewController) window.MathPreviewController.disable();
            window.aceSpellCheckEnabled = false;
        } else {
            visualWrapper.style.display = "none";
            aceWrapper.style.display = "block";
            
            if (cm6View) {
                const content = cm6View.state.doc.toString();
                const cmCursor = window.MudskipperVisualEditor.getCursorPosition(cm6View);
                
                // PERFORMANCE: Only update Ace if content actually changed (normalizing line endings)
                const currentAce = aceEd._originalGetValue();
                if (currentAce.replace(/\r\n/g, '\n') !== content.replace(/\r\n/g, '\n')) {
                    aceEd.session.setValue(content);
                }
                
                // Immediate resize to prevent "blank" editor
                aceEd.resize(true);

                // Defer cursor and focus slightly to ensure Ace has fully processed the layout change
                setTimeout(() => {
                    aceEd.resize(true);
                    aceEd.moveCursorToPosition({ row: cmCursor.row, column: cmCursor.column });
                    aceEd.renderer.scrollCursorIntoView({ row: cmCursor.row, column: cmCursor.column }, 0.5);
                    aceEd.focus();
                }, 10);
            }
            
            // --- RESTORE ACE FEATURES BASED ON SETTINGS ---
            if (document.getElementById('enableMinimapPanel')?.checked && window.enableMinimap) window.enableMinimap();
            if (document.getElementById('enableStickyScrollPanel')?.checked && window.stickyScrollInstance) window.stickyScrollInstance.enable();
            if (document.getElementById('enableMathPreviewPanel')?.checked && window.MathPreviewController) window.MathPreviewController.enable();
            
            window.aceSpellCheckEnabled = true;
            if (window.triggerSpellCheck) window.triggerSpellCheck();
        }
    }
    
    window.updateToggleState(activeFileNameOriginal);
};

window.toggleEditorMode = function() {
    window.setEditorMode(currentMode === 'source' ? 'visual' : 'source');
};

// Intercept file loading to update filename state
(function() {
    const origAddCustomMessageHandler = Shiny.addCustomMessageHandler;
    Shiny.addCustomMessageHandler = function(type, handler) {
        if (type === 'cmdSafeLoadFile' || type === 'updateStatus' || type === 'aceGoTo') {
            const wrappedHandler = function(msg) {
                if (type === 'updateStatus') {
                    const cleanName = msg.replace(/<[^>]*>/g, '').replace(/\*/g, '').trim();
                    if (cleanName && cleanName !== activeFileNameOriginal) {
                        window.updateToggleState(cleanName);
                    }
                }
                
                if (type === 'cmdSafeLoadFile' && currentMode === 'visual' && cm6View) {
                    if (window.MudskipperVisualEditor) {
                        window.MudskipperVisualEditor.setEditorContent(cm6View, msg.content);
                    }
                }

                if (type === 'aceGoTo' && currentMode === 'visual' && cm6View) {
                    if (window.MudskipperVisualEditor) {
                        window.MudskipperVisualEditor.goToLine(cm6View, msg.line);
                    }
                    return; 
                }
                
                handler(msg);
            };
            return origAddCustomMessageHandler.call(Shiny, type, wrappedHandler);
        }
        return origAddCustomMessageHandler.call(Shiny, type, handler);
    };
})();

/**
 * Handle Project State Updates (File List and Base Path)
 * Essential for figure rendering to find files recursively.
 */
Shiny.addCustomMessageHandler('updateProjectState', function(data) {
    if (data && data.files) {
        window.projectFileList = data.files;
    }
    if (data && data.url) {
        window.activeProjectPath = data.url;
    }
});
