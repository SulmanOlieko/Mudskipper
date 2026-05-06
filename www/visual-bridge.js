window.cm6View = null;
window.currentMode = 'source'; // 'source' | 'visual'
let activeFileNameOriginal = '';
window.stopAllEditorActivity = false;
window.activeProjectPath = '';
window.projectFileList = [];

// Helper to check if the editor is currently visible to the user
function isEditorActive() {
    if (window.stopAllEditorActivity) return false;
    const ep = document.getElementById('editorPage');
    if (!ep) return false;
    const style = window.getComputedStyle(ep);
    return style.display !== 'none' && style.visibility !== 'hidden';
}

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
    if (!isEditorActive()) return;

    let filename = activeFileNameOriginal;
    if (!filename || filename.trim() === '') {
        filename = window.currentFilePath || (document.getElementById("activeFileName") ? document.getElementById("activeFileName").innerText.trim() : "");
    }
    const isTex = filename.toLowerCase().endsWith('.tex');
    if (mode === 'visual' && !isTex) return;

    window.currentMode = mode;
    localStorage.setItem('mudskipper.activeEditorMode', mode);

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
                const theme = window.getVisualTheme();

                window.cm6View = window.MudskipperVisualEditor.initVisualEditor(
                    visualWrapper, 
                    content, 
                    (newDoc) => {
                        if (!isEditorActive()) return;
                        // Notify Shiny that content changed without heavy Ace updates
                        if (aceEd.session && (aceEd.session._emit || aceEd.session._signal)) {
                            const method = aceEd.session._emit ? '_emit' : '_signal';
                            aceEd.session[method]('change', { action: 'insert', start: {row:0, column:0}, end: {row:0, column:0}, lines: [] });
                        }
                        
                        // Trigger updates for visual editor
                        if (window.triggerSpellCheck) {
                            clearTimeout(window._visualSpellTimer);
                            window._visualSpellTimer = setTimeout(() => {
                                if (isEditorActive()) window.triggerSpellCheck();
                            }, 1500);
                        }
                        if (window.updateWordCountWithWorker) {
                            window.updateWordCountWithWorker();
                        }
                    },
                    { theme: theme, fontSize: 14 }
                );
                window.cm6View.dom.style.height = "100%";
                window.MudskipperVisualEditor.setCursorPosition(window.cm6View, aceCursor.row, aceCursor.column);
                
                // Immediate spellcheck
                if (window.triggerSpellCheck) window.triggerSpellCheck();
            } else if (window.cm6View) {
                const theme = window.getVisualTheme();
                // Freeze to prevent CM6 change events from corrupting comment offsets
                if (window.commentStore) window.commentStore.freeze();
                window.MudskipperVisualEditor.setEditorContent(window.cm6View, content);
                if (window.commentStore) window.commentStore.unfreeze();
                window.MudskipperVisualEditor.setCursorPosition(window.cm6View, aceCursor.row, aceCursor.column);
                
                // Update theme if it changed
                if (window.cm6View.dispatch && window.MudskipperVisualEditor.setOptionsTheme) {
                    const themeEffects = window.MudskipperVisualEditor.setOptionsTheme({ theme: theme, fontSize: 14 });
                    window.cm6View.dispatch({ effects: themeEffects });
                }
                if (window.triggerSpellCheck) window.triggerSpellCheck();
            }
            
            // --- TEMPORARILY DISABLE ACE FEATURES ---
            if (window.disableMinimap) window.disableMinimap();
            if (window.stickyScrollInstance) window.stickyScrollInstance.disable();
            if (window.MathPreviewController) window.MathPreviewController.disable();
            window.aceSpellCheckEnabled = false;
            
            if (window.updateWordCountWithWorker) window.updateWordCountWithWorker();

            // --- SYNC COMMENT MARKERS TO CM6 ---
            if (window.commentStore && window.cm6View && window.MudskipperVisualEditor) {
                setTimeout(() => {
                    const all = window.commentStore.getAllComments();
                    window.MudskipperVisualEditor.updateCommentDecorations(window.cm6View, all);
                }, 100);
            }
        } else {
            visualWrapper.style.display = "none";
            aceWrapper.style.display = "block";

            if (window.cm6View) {
                const content = window.cm6View.state.doc.toString();
                const cmCursor = window.MudskipperVisualEditor.getCursorPosition(window.cm6View);
                
                // PERFORMANCE: Only update Ace if content actually changed (normalizing line endings)
                const currentAce = aceEd._originalGetValue();
                if (currentAce.replace(/\r\n/g, '\n') !== content.replace(/\r\n/g, '\n')) {
                    // CRITICAL: Freeze CommentStore to prevent setValue's change events
                    // from corrupting all comment offsets. setValue fires a 'remove all' + 
                    // 'insert all' pair of change events that would map every offset to 0.
                    if (window.commentStore) window.commentStore.freeze();
                    aceEd.session.setValue(content);
                    if (window.commentStore) window.commentStore.unfreeze();
                }
                
                aceEd.resize(true);

                // Defer cursor and focus slightly to ensure Ace has fully processed the layout change
                setTimeout(() => {
                    if (!isEditorActive()) return;
                    aceEd.resize(true);
                    aceEd.moveCursorToPosition({ row: cmCursor.row, column: cmCursor.column });
                    if (aceEd.renderer && aceEd.renderer.scrollCursorIntoView) {
                        aceEd.renderer.scrollCursorIntoView({ row: cmCursor.row, column: cmCursor.column }, 0.5);
                    }
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

            // --- SYNC COMMENT MARKERS TO ACE ---
            if (window.commentStore) {
                setTimeout(() => {
                    if (typeof renderAceMarkers === 'function') renderAceMarkers();
                }, 50);
            }
        }
    }
    
    window.updateToggleState(activeFileNameOriginal);
};

window.toggleEditorMode = function() {
    window.setEditorMode(window.currentMode === 'source' ? 'visual' : 'source');
};

// --- HOMEPAGE VISIBILITY MONITOR ---
document.addEventListener('DOMContentLoaded', () => {
    const homePage = document.getElementById('homePage');
    if (homePage) {
        const observer = new MutationObserver(() => {
            const style = window.getComputedStyle(homePage);
            const isVisible = style.display !== 'none' && style.visibility !== 'hidden';
            window.stopAllEditorActivity = isVisible;
            if (isVisible) {
                console.log("[VisualBridge] Homepage visible, stopping background activities");
            }
        });
        observer.observe(homePage, { attributes: true, attributeFilter: ['style', 'class'] });
    }
});

// Intercept file loading to update filename state
(function() {
    const origAddCustomMessageHandler = Shiny.addCustomMessageHandler;
    Shiny.addCustomMessageHandler = function(type, handler) {
        if (type === 'cmdSafeLoadFile' || type === 'updateStatus' || type === 'aceGoTo') {
            const wrappedHandler = function(msg) {
                if (type === 'updateStatus' && typeof msg === 'string') {
                    const cleanName = msg.replace(/<[^>]*>/g, '').replace(/\*/g, '').trim();
                    if (cleanName && cleanName !== activeFileNameOriginal) {
                        window.updateToggleState(cleanName);
                    }
                }
                
                if (type === 'cmdSafeLoadFile' && msg && window.currentMode === 'visual' && window.cm6View) {
                    if (window.MudskipperVisualEditor) {
                        window.MudskipperVisualEditor.setEditorContent(window.cm6View, msg.content);
                    }
                }

                if (type === 'aceGoTo' && msg && window.currentMode === 'visual' && window.cm6View) {
                    if (window.MudskipperVisualEditor) {
                        window.MudskipperVisualEditor.goToLine(window.cm6View, msg.line, msg.column, msg.selectText);
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
    if (data && data.projectId) {
        window.activeProjectId = data.projectId;
    }
});

/**
 * Robust theme detection helper for the visual editor
 * Priority: 1. Manual setting, 2. Global app theme
 */
window.getVisualTheme = function() {
    let settings = {};
    try { settings = JSON.parse(localStorage.getItem('latexerSettings') || '{}'); } catch(e) {}
    const manual = settings.visualEditorTheme || 'light';
    
    if (manual !== 'auto') return manual;
    
    const hasDarkClass = document.body.classList.contains('overall-theme-dark') || 
                        document.documentElement.classList.contains('overall-theme-dark');
    const hasDarkAttr = document.body.getAttribute('data-bs-theme') === 'dark' || 
                       document.documentElement.getAttribute('data-bs-theme') === 'dark';
    
    return (hasDarkClass || hasDarkAttr) ? 'dark' : 'light';
};

// Wait for DOM to be ready before initializing observers and helpers
document.addEventListener('DOMContentLoaded', () => {
    // --- RE-INITIALIZE ON THEME CHANGES ---
    (function() {
        let lastAppliedTheme = window.getVisualTheme();
        
        const themeObserver = new MutationObserver(() => {
            const currentTheme = window.getVisualTheme();
            if (currentTheme !== lastAppliedTheme) {
                lastAppliedTheme = currentTheme;
                if (window.cm6View && window.MudskipperVisualEditor && window.MudskipperVisualEditor.setOptionsTheme) {
                    const themeEffects = window.MudskipperVisualEditor.setOptionsTheme({ 
                        theme: currentTheme, 
                        fontSize: 14 
                    });
                    window.cm6View.dispatch({ effects: themeEffects });
                }
            }
        });

        if (document.documentElement) themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['data-bs-theme', 'class'] });
        if (document.body) themeObserver.observe(document.body, { attributes: true, attributeFilter: ['data-bs-theme', 'class'] });
    })();

    /**
     * Unified helper to insert content into whichever editor is currently active
     */
    window.insertContentToActiveEditor = function(content) {
        if (!content) return;
        
        // Normalize line endings to \n for consistency across editors
        const normalized = content.replace(/\r\n/g, '\n');
        
        if (window.currentMode === 'visual' && window.cm6View) {
            if (window.MudskipperVisualEditor && window.MudskipperVisualEditor.insertText) {
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
                aceEd.insert(normalized);
                aceEd.focus();
            }
        } catch (e) {
            console.error("Failed to insert content into Ace:", e);
        }
    };

    // --- STANDALONE LINTING FOR ACE ---
    let aceLintTimer = null;
    window.triggerAceLinting = function() {
        if (window.currentMode !== 'source' || !isEditorActive()) return;
        try {
            if (typeof ace === 'undefined') return;
            const aceEd = ace.edit("sourceEditor");
            if (!aceEd || !window.MudskipperVisualEditor?.runStandaloneLinter) return;
            
            const text = aceEd.getValue();
            if (!text) return;
            
            const ext = (activeFileNameOriginal || '').split('.').pop().toLowerCase();
            if (ext !== 'tex' && ext !== 'bib') return;
            
            window.MudskipperVisualEditor.runStandaloneLinter(text, ext).then(diagnostics => {
                if (window.currentMode !== 'source' || !aceEd.session || !isEditorActive()) return;
                
                if (window.updateErrorLog) {
                    window.updateErrorLog(diagnostics);
                }

                const annotations = diagnostics.map(d => ({
                    row: d.row,
                    column: d.column,
                    text: d.text,
                    type: d.type === 'info' ? 'information' : d.type
                }));
                
                requestAnimationFrame(() => {
                    if (window.currentMode === 'source' && isEditorActive() && aceEd.session) {
                        try { aceEd.session.setAnnotations(annotations); } catch(e) {}
                    }
                });
            }).catch(e => console.error("Ace linter error:", e));
        } catch (e) {
            console.error("Failed Ace linting:", e);
        }
    };

    if (window.ace) {
        const aceEd = ace.edit("sourceEditor");
        aceEd.on('change', () => {
            if (window.currentMode !== 'source' || !isEditorActive()) return;
            clearTimeout(aceLintTimer);
            aceLintTimer = setTimeout(window.triggerAceLinting, 1500);
        });
    }
});

// Restore saved editor mode on load
document.addEventListener("DOMContentLoaded", function() {
    const savedMode = localStorage.getItem('mudskipper.activeEditorMode');
    if (savedMode === 'visual') {
        let retries = 0;
        const checkReady = setInterval(function() {
            if (window.ace && document.getElementById("sourceEditor") && window.MudskipperVisualEditor) {
                try {
                    // Make sure Ace is fully initialized
                    ace.edit("sourceEditor");
                    clearInterval(checkReady);
                    
                    // We also need to wait for a file to be loaded, otherwise setEditorMode returns early
                    const checkFile = setInterval(function() {
                        const activeFileStr = document.getElementById("activeFileName") ? document.getElementById("activeFileName").innerText.trim() : "";
                        if (isEditorActive() && activeFileStr && activeFileStr !== "No file selected") {
                            clearInterval(checkFile);
                            window.setEditorMode('visual');
                        }
                    }, 200);
                } catch (e) {}
            }
            if (++retries > 50) clearInterval(checkReady); // Give up after 5s
        }, 100);
    }
});
