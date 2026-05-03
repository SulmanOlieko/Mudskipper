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
        } else {
            visualBtn.classList.add("disabled");
            if (window.currentMode === 'visual') {
                window.setEditorMode('source');
            }
        }
    }
    
    if (visualBtn && sourceBtn) {
        if (window.currentMode === 'visual' && isTex) {
            visualBtn.classList.add("active");
            sourceBtn.classList.remove("active");
        } else {
            sourceBtn.classList.add("active");
            visualBtn.classList.remove("active");
            window.currentMode = 'source'; 
        }
    }
};

/**
 * Set the editor mode (source or visual)
 */
window.setEditorMode = function(mode) {
    if (!isEditorActive()) return;
    
    const isTex = activeFileNameOriginal.toLowerCase().endsWith('.tex');
    if (mode === 'visual' && !isTex) return;
    
    window.currentMode = mode;
    
    const aceWrapper = document.getElementById("sourceEditor");
    const visualWrapper = document.getElementById("visualEditorContainer");
    
    if (window.ace) {
        const aceEd = ace.edit("sourceEditor");
        
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
                        // Signal change to Shiny
                        if (aceEd.session && aceEd.session._signal) {
                            aceEd.session._signal('change', { action: 'insert', start: {row:0, column:0}, end: {row:0, column:0}, lines: [] });
                        }
                    },
                    { theme: theme, fontSize: 14 }
                );
                window.cm6View.dom.style.height = "100%";
                window.MudskipperVisualEditor.setCursorPosition(window.cm6View, aceCursor.row, aceCursor.column);
                
                // Trigger spellcheck for visual mode
                if (window.triggerSpellCheck) window.triggerSpellCheck();
            } else if (window.cm6View) {
                window.MudskipperVisualEditor.setEditorContent(window.cm6View, content);
                window.MudskipperVisualEditor.setCursorPosition(window.cm6View, aceCursor.row, aceCursor.column);
                if (window.triggerSpellCheck) window.triggerSpellCheck();
            }
        } else {
            visualWrapper.style.display = "none";
            aceWrapper.style.display = "block";
            
            if (window.cm6View) {
                const content = window.cm6View.state.doc.toString();
                const cmCursor = window.MudskipperVisualEditor.getCursorPosition(window.cm6View);
                const currentAce = aceEd._originalGetValue();
                if (currentAce !== content) {
                    aceEd.session.setValue(content);
                }
                aceEd.resize(true);
                setTimeout(() => {
                    if (!isEditorActive()) return;
                    aceEd.resize(true);
                    aceEd.moveCursorToPosition({ row: cmCursor.row, column: cmCursor.column });
                    aceEd.focus();
                }, 50);
            }
        }
    }
    window.updateToggleState(activeFileNameOriginal);
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
                    window.MudskipperVisualEditor.setEditorContent(window.cm6View, msg.content);
                }
                if (type === 'aceGoTo' && msg && window.currentMode === 'visual' && window.cm6View) {
                    window.MudskipperVisualEditor.goToLine(window.cm6View, msg.line, msg.column, msg.selectText);
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

window.getVisualTheme = function() {
    let settings = {};
    try { settings = JSON.parse(localStorage.getItem('latexerSettings') || '{}'); } catch(e) {}
    const manual = settings.visualEditorTheme || 'light';
    if (manual !== 'auto') return manual;
    const isDark = document.body.classList.contains('overall-theme-dark') || 
                   document.documentElement.classList.contains('overall-theme-dark') ||
                   document.body.getAttribute('data-bs-theme') === 'dark';
    return isDark ? 'dark' : 'light';
};

document.addEventListener('DOMContentLoaded', () => {
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
                
                // Diagnostics are now enriched with .row, .column, .text, .type from latex-linter.ts
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
