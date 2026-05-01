window.cm6View = null;
window.currentMode = 'source'; // 'source' | 'visual'
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
            if (window.currentMode === 'visual') {
                window.setEditorMode('source');
            }
        }
    }
    
    if (visualBtn && sourceBtn) {
        if (window.currentMode === 'visual' && isTex) {
            visualBtn.classList.add("active");
            sourceBtn.classList.remove("active");
            visualBtn.setAttribute("aria-selected", "true");
            sourceBtn.setAttribute("aria-selected", "false");
        } else {
            sourceBtn.classList.add("active");
            visualBtn.classList.remove("active");
            sourceBtn.setAttribute("aria-selected", "true");
            visualBtn.setAttribute("aria-selected", "false");
            window.currentMode = 'source'; 
        }
    }
};

/**
 * Set the editor mode (source or visual)
 */
window.setEditorMode = function(mode) {
    const isTex = activeFileNameOriginal.toLowerCase().endsWith('.tex');
    if (mode === 'visual' && !isTex) return;
    
    window.currentMode = mode;
    
    const aceWrapper = document.getElementById("sourceEditor");
    const visualWrapper = document.getElementById("visualEditorContainer");
    
    if (window.ace) {
        const aceEd = ace.edit("sourceEditor");
        
        // --- MONKEY PATCH ACE TO SYNC WITH VISUAL EDITOR ---
        if (!aceEd._originalGetValue) {
            aceEd._originalGetValue = aceEd.getValue.bind(aceEd);
            aceEd.getValue = function() {
                if (window.currentMode === 'visual' && window.cm6View) {
                    return window.cm6View.state.doc.toString();
                }
                return aceEd._originalGetValue();
            };
        }

        if (window.currentMode === 'visual') {
            const content = aceEd._originalGetValue();
            const aceCursor = aceEd.getCursorPosition();
            
            aceWrapper.style.display = "none";
            visualWrapper.style.display = "block";
            
            if (!window.cm6View && window.MudskipperVisualEditor) {
                // Robust theme detection
                const hasDarkClass = document.body.classList.contains('overall-theme-dark') || 
                                    document.documentElement.classList.contains('overall-theme-dark');
                const hasDarkAttr = document.body.getAttribute('data-bs-theme') === 'dark' || 
                                   document.documentElement.getAttribute('data-bs-theme') === 'dark';
                
                const isDarkMode = hasDarkClass || hasDarkAttr;
                const theme = isDarkMode ? 'dark' : 'light';
                
                console.log('[VisualBridge] Theme detection:', { 
                    isDarkMode, 
                    hasDarkClass, 
                    hasDarkAttr,
                    bodyClasses: document.body.className 
                });
                
                window.cm6View = window.MudskipperVisualEditor.initVisualEditor(
                    visualWrapper, 
                    content, 
                    (newDoc) => {
                        // Notify Shiny that content changed without heavy Ace updates
                        if (aceEd.session && aceEd.session._emit) {
                            aceEd.session._emit('change', { action: 'insert', start: {row:0, column:0}, end: {row:0, column:0}, lines: [] });
                        } else if (aceEd.session && aceEd.session._signal) {
                            aceEd.session._signal('change', { action: 'insert', start: {row:0, column:0}, end: {row:0, column:0}, lines: [] });
                        }
                        
                        // Trigger updates for visual editor
                        if (window.triggerSpellCheck) {
                            clearTimeout(window._visualSpellTimer);
                            window._visualSpellTimer = setTimeout(() => window.triggerSpellCheck(), 1500);
                        }
                        if (window.updateWordCountWithWorker) {
                            window.updateWordCountWithWorker();
                        }
                    },
                    { theme: theme, fontSize: 14 }
                );
                window.cm6View.dom.style.height = "100%";
                window.MudskipperVisualEditor.setCursorPosition(window.cm6View, aceCursor.row, aceCursor.column);
            } else if (window.cm6View) {
                const hasDarkClass = document.body.classList.contains('overall-theme-dark') || 
                                    document.documentElement.classList.contains('overall-theme-dark');
                const hasDarkAttr = document.body.getAttribute('data-bs-theme') === 'dark' || 
                                   document.documentElement.getAttribute('data-bs-theme') === 'dark';
                
                const isDarkMode = hasDarkClass || hasDarkAttr;
                const theme = isDarkMode ? 'dark' : 'light';
                
                window.MudskipperVisualEditor.setEditorContent(window.cm6View, content);
                window.MudskipperVisualEditor.setCursorPosition(window.cm6View, aceCursor.row, aceCursor.column);
                
                // Update theme if it changed
                if (window.cm6View.dispatch && window.MudskipperVisualEditor.setOptionsTheme) {
                    const themeEffects = window.MudskipperVisualEditor.setOptionsTheme({ theme: theme, fontSize: 14 });
                    window.cm6View.dispatch({
                        effects: themeEffects
                    });
                }
            }
            
            // --- TEMPORARILY DISABLE ACE FEATURES ---
            if (window.disableMinimap) window.disableMinimap();
            if (window.stickyScrollInstance) window.stickyScrollInstance.disable();
            if (window.MathPreviewController) window.MathPreviewController.disable();
            window.aceSpellCheckEnabled = false;
            
            // Immediate sync for status bar
            if (window.triggerSpellCheck) window.triggerSpellCheck();
            if (window.updateWordCountWithWorker) window.updateWordCountWithWorker();
        } else {
            visualWrapper.style.display = "none";
            aceWrapper.style.display = "block";
            
            if (window.cm6View) {
                const content = window.cm6View.state.doc.toString();
                const cmCursor = window.MudskipperVisualEditor.getCursorPosition(window.cm6View);
                
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
            if (window.updateWordCountWithWorker) window.updateWordCountWithWorker();
        }
    }
    
    window.updateToggleState(activeFileNameOriginal);
};

window.toggleEditorMode = function() {
    window.setEditorMode(window.currentMode === 'source' ? 'visual' : 'source');
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
                
                if (type === 'cmdSafeLoadFile' && window.currentMode === 'visual' && window.cm6View) {
                    if (window.MudskipperVisualEditor) {
                        window.MudskipperVisualEditor.setEditorContent(window.cm6View, msg.content);
                    }
                }

                if (type === 'aceGoTo' && window.currentMode === 'visual' && window.cm6View) {
                    if (window.MudskipperVisualEditor) {
                        window.MudskipperVisualEditor.goToLine(window.cm6View, msg.line);
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

// Wait for DOM to be ready before initializing observers and helpers
document.addEventListener('DOMContentLoaded', () => {
    // --- RE-INITIALIZE ON THEME CHANGES ---
    (function() {
        const themeObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'attributes' && (mutation.attributeName === 'data-bs-theme' || mutation.attributeName === 'class')) {
                    if (window.cm6View && window.MudskipperVisualEditor && window.MudskipperVisualEditor.setOptionsTheme) {
                        setTimeout(() => {
                            const hasDarkClass = document.body.classList.contains('overall-theme-dark') || 
                                                document.documentElement.classList.contains('overall-theme-dark');
                            const hasDarkAttr = document.body.getAttribute('data-bs-theme') === 'dark' || 
                                               document.documentElement.getAttribute('data-bs-theme') === 'dark';
                            const isDarkMode = hasDarkClass || hasDarkAttr;
                            const theme = isDarkMode ? 'dark' : 'light';
                            
                            console.log('[VisualBridge] Theme change detected (observer):', theme);
                            const themeEffects = window.MudskipperVisualEditor.setOptionsTheme({ theme: theme, fontSize: 14 });
                            window.cm6View.dispatch({
                                effects: themeEffects
                            });
                        }, 50);
                    }
                }
            });
        });

        if (document.documentElement) themeObserver.observe(document.documentElement, { attributes: true });
        if (document.body) themeObserver.observe(document.body, { attributes: true });
    })();

    /**
     * Unified helper to insert content into whichever editor is currently active
     */
    window.insertContentToActiveEditor = function(content) {
        if (!content) return;
        
        // Normalize line endings to \n for consistency across editors
        const normalized = content.replace(/\r\n/g, '\n');
        console.log('[VisualBridge] Inserting content. Mode:', window.currentMode, 'Content:', normalized.substring(0, 20) + (normalized.length > 20 ? '...' : ''));
        
        if (window.currentMode === 'visual' && window.cm6View) {
            if (window.MudskipperVisualEditor && window.MudskipperVisualEditor.insertText) {
                console.log('[VisualBridge] Inserting into CM6');
                window.MudskipperVisualEditor.insertText(window.cm6View, normalized);
                return;
            } else {
                console.warn('[VisualBridge] CM6 active but insertText API not found');
            }
        }
        
        // Fallback to Ace
        try {
            const aceEd = ace.edit("sourceEditor");
            if (aceEd) {
                console.log('[VisualBridge] Inserting into Ace');
                aceEd.insert(normalized);
                aceEd.focus();
            }
        } catch (e) {
            console.error("Failed to insert content into Ace:", e);
        }
    };
});
