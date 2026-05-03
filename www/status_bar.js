/**
 * status_bar.js  —  Mudskipper VS Code-style status bar
 *
 * Design rules (per user spec):
 *  - Background: --tblr-body-bg slightly darkened (white in light / dark in dark)
 *  - Border:     --tblr-border-color top line
 *  - Text:       --tblr-body-color (contrasts with background)
 *  - Compile chip ONLY uses --tblr-primary colour
 *  - Visible ONLY when #editorPage is in the DOM and visible
 */

(function () {
  'use strict';

  // ─── Internal State ────────────────────────────────────────────────────────
  const SB = {
    line        : 1,
    col         : 1,
    totalLines  : 0,
    words       : 0,
    fileMode    : '',
    isCompiling : false,
    compileLabel: 'Ready',   // mirrors the compile button text
    autoCompile  : false,
    compileMode  : 'normal',    // 'normal' | 'fast'
    syntaxCheck  : 'none',      // 'before' | 'none'
    errorHandling: 'tryCompile',// 'stopFirst' | 'tryCompile'
    saveIndicator: 'saved',     // 'saving' | 'saved'
    spellErrors : 0,
    citations   : 0,
    labels      : 0,
    annErrors   : 0,
    annWarnings : 0,
    annInfos    : 0,
  };

  // ─── SVG icons (14×14) ─────────────────────────────────────────────────────
  const IC = {
    play    : `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg>`,
    cursor  : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12h18M12 3v18"/></svg>`,
    lines   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`,
    globe   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>`,
    save    : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>`,
    words   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6h16M4 12h16M4 18h12"/></svg>`,
    spell   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 18L3 21l3-3"/><path d="M21 3l-9 9"/><path d="M9 3H3v6"/></svg>`,
    cite    : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 10h2a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2H6v10M14 10h2a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2v10"/></svg>`,
    label   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="2"/></svg>`,
    error   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`,
    warning : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`,
    info    : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>`,
    auto    : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>`,
    flash   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>`,
    check   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>`,
    shield  : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>`,
    clock   : `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>`,
  };

  // ─── Build the bar DOM ─────────────────────────────────────────────────────
  function buildBar() {
    const bar = document.createElement('div');
    bar.id = 'mudskipper-status-bar';

    // Helper: chip
    // Tabler/Bootstrap 5 tooltips: data-bs-toggle + title + placement="top"
    // (placement="top" is correct for a bar fixed at the bottom of the screen).
    function chip(id, title, inner, extra) {
      const d = document.createElement('div');
      d.className = 'msb-chip' + (extra ? ' ' + extra : '');
      d.id = id;
      d.title = title;
      d.setAttribute('data-bs-toggle', 'tooltip');
      d.setAttribute('data-bs-placement', 'top');
      d.innerHTML = inner;
      return d;
    }
    function sep() {
      const d = document.createElement('div');
      d.className = 'msb-sep';
      return d;
    }

    // LEFT ─ compile chip + mode + auto-compile
    const left = document.createElement('div');
    left.className = 'msb-section msb-left';

    const compileChip = chip('msb-compile-chip',
      'Click to compile / shows compile stage',
      IC.play + '<span id="msb-compile-label">Ready</span>',
      'msb-chip-primary msb-clickable'
    );
    compileChip.addEventListener('click', () => {
      const btn = document.getElementById('compile');
      if (btn) btn.click();
    });

    const modeChip = chip('msb-mode-chip',
      'File language / editor mode',
      IC.globe + '<span id="msb-mode-label">—</span>'
    );

    const autoChip = chip('msb-auto-chip',
      'Auto-compile state',
      IC.auto + '<span id="msb-auto-dot" class="msb-dot msb-dot-off"></span><span id="msb-auto-label">Auto off</span>'
    );

    // COMPILE MODE chip (Normal / Fast draft)
    const compileModeChip = chip('msb-cmode-chip',
      'Compile mode — Normal (full) or Fast (draft)',
      IC.flash + '<span id="msb-cmode-label">Normal</span>'
    );

    // SYNTAX CHECK chip
    const syntaxChip = chip('msb-syntax-chip',
      'Syntax check — checked before compile or skipped',
      IC.check + '<span id="msb-syntax-label">No syntax</span>'
    );

    // ERROR HANDLING chip
    const errHandlingChip = chip('msb-errh-chip',
      'Compile error handling — stop on first error or try to compile',
      IC.shield + '<span id="msb-errh-label">Try compile</span>'
    );

    left.appendChild(compileChip);
    left.appendChild(sep());
    left.appendChild(modeChip);
    left.appendChild(sep());
    left.appendChild(autoChip);
    left.appendChild(sep());
    left.appendChild(compileModeChip);
    left.appendChild(sep());
    left.appendChild(syntaxChip);
    left.appendChild(sep());
    left.appendChild(errHandlingChip);

    // CENTER ─ save + cursor + total lines + words
    const center = document.createElement('div');
    center.className = 'msb-section msb-center';

    const saveChip = chip('msb-save-chip',
      'Auto-save status',
      IC.save + '<span id="msb-save-label">Saved</span>'
    );

    const cursorChip = chip('msb-cursor-chip',
      'Cursor position — click to go to line',
      IC.cursor + '<span id="msb-cursor-label">Ln 1, Col 1</span>',
      'msb-clickable'
    );
    cursorChip.addEventListener('click', () => {
      try {
        const editor = ace.edit('sourceEditor');
        const ln = prompt('Go to line:', SB.line);
        if (ln !== null) {
          const n = parseInt(ln, 10);
          if (!isNaN(n)) { editor.gotoLine(n, 0, true); editor.focus(); }
        }
      } catch(e) {}
    });

    const linesChip = chip('msb-lines-chip',
      'Total lines in file',
      IC.lines + '<span id="msb-lines-label">0 lines</span>'
    );

    const wordsChip = chip('msb-words-chip',
      'Word count — click for details',
      IC.words + '<span id="msb-words-label">0 words</span>',
      'msb-clickable'
    );
    wordsChip.addEventListener('click', () => {
      if (window.openWordCountOverlay) openWordCountOverlay();
    });

    center.appendChild(saveChip);
    center.appendChild(sep());
    center.appendChild(cursorChip);
    center.appendChild(sep());
    center.appendChild(linesChip);
    center.appendChild(sep());
    center.appendChild(wordsChip);

    // RIGHT ─ errors/warnings/infos + spell + citations + labels + clock
    const right = document.createElement('div');
    right.className = 'msb-section msb-right';

    const errChip = chip('msb-err-chip',
      'Compile errors in document',
      IC.error + '<span id="msb-err-label">0</span>'
    );
    const warnChip = chip('msb-warn-chip',
      'Compile warnings in document',
      IC.warning + '<span id="msb-warn-label">0</span>'
    );
    const infoChip = chip('msb-info-chip',
      'Compile notes in document',
      IC.info + '<span id="msb-info-label">0</span>'
    );
    const spellChip = chip('msb-spell-chip',
      'Spell-check errors',
      IC.spell + '<span id="msb-spell-label">—</span>'
    );
    const citeChip = chip('msb-cite-chip',
      'Bibliography references — click to manage',
      IC.cite + '<span id="msb-cite-label">0 refs</span>',
      'msb-clickable'
    );
    citeChip.addEventListener('click', () => {
      if (window.openCitationOverlay) openCitationOverlay();
    });
    const labelChip = chip('msb-label-chip',
      'Cross-reference labels in document',
      IC.label + '<span id="msb-label-label">0 labels</span>'
    );
    const clockChip = chip('msb-clock-chip',
      'Local time',
      IC.clock + '<span id="msb-clock-label">—</span>',
      'msb-chip-clock'
    );

    right.appendChild(errChip);
    right.appendChild(sep());
    right.appendChild(warnChip);
    right.appendChild(sep());
    right.appendChild(infoChip);
    right.appendChild(sep());
    right.appendChild(spellChip);
    right.appendChild(sep());
    right.appendChild(citeChip);
    right.appendChild(sep());
    right.appendChild(labelChip);
    right.appendChild(sep());
    right.appendChild(clockChip);

    bar.appendChild(left);
    bar.appendChild(center);
    bar.appendChild(right);
    return bar;
  }

  // ─── Render helpers ────────────────────────────────────────────────────────
  function txt(id, s) {
    const el = document.getElementById(id);
    if (el) el.textContent = String(s);
  }
  function cls(id, c, on) {
    const el = document.getElementById(id);
    if (!el) return;
    on ? el.classList.add(c) : el.classList.remove(c);
  }

  // ─── Individual renderers ──────────────────────────────────────────────────

  function renderCompile() {
    const chip = document.getElementById('msb-compile-chip');
    if (!chip) return;
    txt('msb-compile-label', SB.compileLabel);
    if (SB.isCompiling) {
      chip.classList.add('msb-compiling');
    } else {
      chip.classList.remove('msb-compiling');
    }
  }

  function renderMode() {
    const MAP = {
      latex: 'LaTeX', bibtex: 'BibTeX', text: 'Plain Text',
      javascript: 'JS', typescript: 'TS', python: 'Python',
      r: 'R', markdown: 'Markdown', html: 'HTML', css: 'CSS',
      json: 'JSON', yaml: 'YAML', sh: 'Shell', xml: 'XML', sql: 'SQL',
    };
    const raw = (SB.fileMode || '').toLowerCase();
    txt('msb-mode-label', MAP[raw] || SB.fileMode || '—');
  }

  function renderAutoCompile() {
    const dot = document.getElementById('msb-auto-dot');
    if (dot) dot.className = 'msb-dot ' + (SB.autoCompile ? 'msb-dot-on' : 'msb-dot-off');
    txt('msb-auto-label', SB.autoCompile ? 'Auto on' : 'Auto off');
  }

  function renderSave() {
    const chip = document.getElementById('msb-save-chip');
    if (!chip) return;
    if (SB.saveIndicator === 'saving') {
      txt('msb-save-label', 'Saving…');
      chip.classList.add('msb-saving');
    } else {
      txt('msb-save-label', 'Saved');
      chip.classList.remove('msb-saving');
    }
  }

  function renderCursor() {
    txt('msb-cursor-label', `Ln ${SB.line}, Col ${SB.col}`);
  }

  function renderLines() {
    txt('msb-lines-label', SB.totalLines.toLocaleString() + ' lines');
  }

  function renderWords() {
    txt('msb-words-label', SB.words.toLocaleString() + ' words');
  }

  function renderAnnotations() {
    const e = SB.annErrors, w = SB.annWarnings, i = SB.annInfos;
    txt('msb-err-label',  e);
    txt('msb-warn-label', w);
    txt('msb-info-label', i);
    cls('msb-err-chip',  'msb-has-errors',   e > 0);
    cls('msb-warn-chip', 'msb-has-warnings', w > 0);
    cls('msb-info-chip', 'msb-has-infos',    i > 0);
  }

  function renderSpell() {
    const n = SB.spellErrors;
    txt('msb-spell-label', n === 0 ? 'No errors' : n + (n === 1 ? ' typo' : ' typos'));
    cls('msb-spell-chip', 'msb-has-errors', n > 0);
  }

  function renderCitations() {
    const n = SB.citations;
    txt('msb-cite-label', n + (n === 1 ? ' ref' : ' refs'));
  }

  function renderLabels() {
    const n = SB.labels;
    txt('msb-label-label', n + (n === 1 ? ' label' : ' labels'));
  }

  function renderClock() {
    const d = new Date();
    txt('msb-clock-label',
      d.getHours().toString().padStart(2, '0') + ':' +
      d.getMinutes().toString().padStart(2, '0'));
  }

  function renderCompileOptions() {
    // Compile mode: 'normal' -> 'Normal', 'fast' -> 'Fast [draft]'
    const modeMap = { normal: 'Normal', fast: 'Fast [draft]' };
    txt('msb-cmode-label', modeMap[SB.compileMode] || SB.compileMode || 'Normal');
    cls('msb-cmode-chip', 'msb-opt-active', SB.compileMode === 'fast');

    // Syntax check: 'before' -> 'Syntax on', 'none' -> 'No syntax'
    txt('msb-syntax-label', SB.syntaxCheck === 'before' ? 'Syntax on' : 'No syntax');
    cls('msb-syntax-chip', 'msb-opt-active', SB.syntaxCheck === 'before');

    // Error handling: 'stopFirst' -> 'Stop on err', 'tryCompile' -> 'Try compile'
    const ehMap = { stopFirst: 'Stop on err', tryCompile: 'Try compile' };
    txt('msb-errh-label', ehMap[SB.errorHandling] || 'Try compile');
    cls('msb-errh-chip', 'msb-opt-warn', SB.errorHandling === 'stopFirst');
  }

  function renderAll() {
    renderCompile();
    renderMode();
    renderAutoCompile();
    renderCompileOptions();
    renderSave();
    renderCursor();
    renderLines();
    renderWords();
    renderAnnotations();
    renderSpell();
    renderCitations();
    renderLabels();
    renderClock();
  }

  // ─── Visibility: only show on editor page ──────────────────────────────────
  // Shiny wraps the editor in conditionalPanel(condition="output.showHomepage==false")
  // Shiny sets display:none on the conditional panel wrapper div when the condition
  // is false. #editorPage is inside that wrapper.
  // Strategy: The bar is visible when #homePage is NOT visible (i.e. we're on editor).
  function hookEditorPageVisibility() {
    const bar = document.getElementById('mudskipper-status-bar');
    if (!bar) return;

    function isEditorVisible() {
      // Method 1: Check if #editorPage exists and is visible (not hidden by ancestor)
      const ep = document.getElementById('editorPage');
      if (!ep) return false;
      // Walk up to check for display:none
      let node = ep;
      while (node && node !== document.body) {
        const s = window.getComputedStyle(node);
        if (s.display === 'none' || s.visibility === 'hidden') return false;
        node = node.parentElement;
      }
      return true;
    }

    function update() {
      const visible = isEditorVisible();
      bar.style.display = visible ? 'flex' : 'none';
    }

    // Watch the editorPage div for style/class changes
    const ep = document.getElementById('editorPage');
    if (ep) {
      new MutationObserver(update).observe(ep, {
        attributes: true, attributeFilter: ['style', 'class']
      });
    }

    // Also watch body for any dynamically added/removed editorPage
    new MutationObserver(update).observe(document.body, {
      childList: true, subtree: false
    });

    update();
  }

  // ─── Hook: Editors (Ace & CodeMirror 6) ──────────────────────────────────
  function hookEditors() {
    let aceHooked = false;
    let cm6Hooked = false;

    function tryHookAce() {
      if (aceHooked) return true;
      try {
        const ed = ace.edit('sourceEditor');
        if (!ed) return false;

        ed.selection.on('changeCursor', () => {
          if (window.currentMode === 'source') {
            const p = ed.getCursorPosition();
            SB.line = p.row + 1;
            SB.col  = p.column + 1;
            renderCursor();
          }
        });
        ed.getSession().on('change', () => {
          if (window.currentMode === 'source') {
            SB.totalLines = ed.getSession().getLength();
            renderLines();
          }
        });
        ed.getSession().on('changeMode', () => {
          SB.fileMode = (ed.getSession().getMode().$id || '').replace('ace/mode/', '');
          renderMode();
        });

        aceHooked = true;
        return true;
      } catch(e) { return false; }
    }

    function tryHookCM6() {
      if (cm6Hooked) return true;
      if (!window.cm6View) return false;

      // CM6 reactivity: listen for cursorPosition Shiny input as a proxy
      // or directly check if we can add a listener.
      // Better: check currentMode in a loop or poll for CM6 cursor.
      cm6Hooked = true;
      return true;
    }

    // Polling for both
    setInterval(() => {
      tryHookAce();
      tryHookCM6();

      if (window.currentMode === 'visual' && window.cm6View) {
        const view = window.cm6View;
        const pos = view.state.selection.main.head;
        const line = view.state.doc.lineAt(pos);
        const newLine = line.number;
        const newCol = pos - line.from + 1;
        const newTotal = view.state.doc.lines;

        if (SB.line !== newLine || SB.col !== newCol) {
          SB.line = newLine;
          SB.col = newCol;
          renderCursor();
        }
        if (SB.totalLines !== newTotal) {
          SB.totalLines = newTotal;
          renderLines();
        }
        // Visual mode is always TeX
        if (SB.fileMode !== 'latex') {
          SB.fileMode = 'latex';
          renderMode();
        }
      } else if (window.currentMode === 'source') {
        // Ace handled by events, but initial read might be needed
        try {
          const ed = ace.edit('sourceEditor');
          const p = ed.getCursorPosition();
          const newLine = p.row + 1;
          const newCol = p.column + 1;
          const newTotal = ed.getSession().getLength();
          const newMode = (ed.getSession().getMode().$id || '').replace('ace/mode/', '');

          if (SB.line !== newLine || SB.col !== newCol) {
            SB.line = newLine;
            SB.col = newCol;
            renderCursor();
          }
          if (SB.totalLines !== newTotal) {
            SB.totalLines = newTotal;
            renderLines();
          }
          if (SB.fileMode !== newMode) {
            SB.fileMode = newMode;
            renderMode();
          }
        } catch(e) {}
      }
    }, 300);
  }

  // ─── Hook: Word count ─────────────────────────────────────────────────────
  function hookWordCount() {
    let patched = false;
    function tryPatch() {
      if (patched) return true;
      if (typeof window.updateWordCounterDisplay !== 'function') return false;
      const orig = window.updateWordCounterDisplay;
      window.updateWordCounterDisplay = function(stats) {
        orig.apply(this, arguments);
        if (stats && stats.total) {
          SB.words = stats.total.words;
          renderWords();
        }
      };
      if (window.currentStats && window.currentStats.total) {
        SB.words = window.currentStats.total.words;
        renderWords();
      }
      patched = true;
      return true;
    }
    if (!tryPatch()) {
      let n = 0;
      const iv = setInterval(() => { if (tryPatch() || ++n > 30) clearInterval(iv); }, 500);
    }
  }

  // ─── Hook: Spell check (poll Misspelled markers/decorations) ──────────────
  function hookSpellCheck() {
    setInterval(() => {
      let c = 0;
      if (window.currentMode === 'visual' && window.cm6View) {
        if (window.MudskipperVisualEditor && window.MudskipperVisualEditor.getSpellcheckErrorCount) {
          c = window.MudskipperVisualEditor.getSpellcheckErrorCount(window.cm6View);
        }
      } else {
        try {
          const markers = ace.edit('sourceEditor').getSession().getMarkers();
          Object.keys(markers).forEach(k => { if (markers[k].clazz === 'misspelled') c++; });
        } catch(e) {}
      }
      if (c !== SB.spellErrors) { SB.spellErrors = c; renderSpell(); }
    }, 2000);
  }

  // ─── Hook: Shiny custom messages ──────────────────────────────────────────
  function hookShiny() {
    let hooked = false;
    function tryHook() {
      if (hooked) return true;
      if (typeof Shiny === 'undefined' || !Shiny.addCustomMessageHandler) return false;

      // updateStatus — writes filename (possibly dirty-state HTML) to #statusBar
      // in the navbar next to the project name. Also syncs the save chip label.
      Shiny.addCustomMessageHandler('updateStatus', function(msg) {
        const el = document.getElementById('statusBar');
        if (el) el.innerHTML = msg || '';
        // Detect dirty state: R sends an orange <span>…*</span> for unsaved files
        const isDirty = typeof msg === 'string' && msg.includes('*');
        SB.saveIndicator = isDirty ? 'saving' : 'saved';
        renderSave();
      });

      // Citations
      Shiny.addCustomMessageHandler('updateCitationCount', n => {
        SB.citations = parseInt(n, 10) || 0;
        renderCitations();
      });

      // Labels
      Shiny.addCustomMessageHandler('updateLabelCount', n => {
        SB.labels = parseInt(n, 10) || 0;
        renderLabels();
      });

      hooked = true;
      return true;
    }
    if (!tryHook()) {
      let n = 0;
      const iv = setInterval(() => { if (tryHook() || ++n > 30) clearInterval(iv); }, 400);
    }
  }

  // ─── Hook: Compile button text (MutationObserver on #compile) ─────────────
  function hookCompileStages() {
    let watching = false;
    function tryHook() {
      if (watching) return true;
      const btn = document.getElementById('compile');
      if (!btn) return false;

      // Extract the human-readable stage text from the button's innerText
      // (stripping the spinner element and trimming whitespace)
      function readBtnText() {
        // Clone so we can remove child nodes without affecting DOM
        const clone = btn.cloneNode(true);
        // Remove spinner span if present
        const sp = clone.querySelector('#compileSpinner, .spinner-border, span');
        if (sp) sp.remove();
        return (clone.innerText || clone.textContent || '').trim().replace(/\s+/g, ' ');
      }

      function update() {
        const text = readBtnText();
        if (!text) return;
        SB.compileLabel = text;
        SB.isCompiling = (text !== 'Recompile' && text !== 'Ready');
        renderCompile();
      }

      // Watch the compile button for any content change
      new MutationObserver(update).observe(btn, {
        childList: true,
        subtree: true,
        characterData: true,
        attributes: false,
      });

      // Also watch the spinner separately for reliable done-state
      const spinner = document.getElementById('compileSpinner');
      if (spinner) {
        new MutationObserver(() => {
          const visible = spinner.style.display !== 'none' && spinner.style.display !== '';
          SB.isCompiling = visible;
          if (!visible) {
            // Read actual button label when compile ends
            const t = readBtnText();
            SB.compileLabel = t || 'Recompile';
          }
          renderCompile();
        }).observe(spinner, { attributes: true, attributeFilter: ['style'] });
      }

      update(); // read initial state
      watching = true;
      return true;
    }

    if (!tryHook()) {
      let n = 0;
      const iv = setInterval(() => { if (tryHook() || ++n > 40) clearInterval(iv); }, 350);
    }
  }

  // hookCompileSpinner is now merged into hookCompileStages above.
  // Keeping this as a no-op stub so init() call order doesn't break.
  function hookCompileSpinner() {}


  // ─── Hook: Annotations (errors/warnings/infos) ────────────────────────────
  // The setAnnotations Shiny handler already runs in ui_main.R.
  // We patch window.updateErrorLog (called from within that handler)
  // AND watch the errorLogBadge element as a fallback.
  function hookAnnotations() {
    // Patch approach: install our own updateErrorLog before the existing one does
    const origUpdateErrorLog = window.updateErrorLog;
    window.updateErrorLog = function(annotations) {
      if (typeof origUpdateErrorLog === 'function') origUpdateErrorLog.apply(this, arguments);
      if (!annotations) return;
      let e = 0, w = 0, i = 0;
      annotations.forEach(a => {
        if (a.type === 'error') e++;
        else if (a.type === 'warning') w++;
        else i++;
      });
      SB.annErrors   = e;
      SB.annWarnings = w;
      SB.annInfos    = i;
      renderAnnotations();
    };

    // Fallback: watch errorLogBadge for changes
    function fromBadge() {
      const badge = document.getElementById('errorLogBadge');
      if (!badge) return;
      new MutationObserver(() => {
        // We can't split from badge alone, so only use if updateErrorLog didn't fire
        const total = parseInt(badge.textContent, 10) || 0;
        if (SB.annErrors + SB.annWarnings + SB.annInfos !== total) {
          // We know total but not split — best effort
          const isRed    = badge.classList.contains('bg-red');
          const isOrange = badge.classList.contains('bg-orange');
          if (isRed) { SB.annErrors = total; SB.annWarnings = 0; SB.annInfos = 0; }
          else if (isOrange) { SB.annErrors = 0; SB.annWarnings = total; SB.annInfos = 0; }
          else { SB.annErrors = 0; SB.annWarnings = 0; SB.annInfos = total; }
          renderAnnotations();
        }
      }).observe(badge, { characterData: true, childList: true, attributes: true });
    }

    const tryBadge = () => {
      if (document.getElementById('errorLogBadge')) { fromBadge(); return true; }
      return false;
    };
    if (!tryBadge()) {
      let n = 0;
      const iv = setInterval(() => { if (tryBadge() || ++n > 30) clearInterval(iv); }, 400);
    }
  }

  // ─── Hook: Auto-compile radio buttons ─────────────────────────────────────
  // The radio buttons use name="autoCompile" with values "on"/"off".
  // We listen for change on the document (delegated) and also read initial state.
  function hookAutoCompile() {
    function readCurrent() {
      const on = document.querySelector('input[name="autoCompile"][value="on"]');
      if (on) {
        SB.autoCompile = on.checked;
        renderAutoCompile();
        return true;
      }
      return false;
    }

    // Delegated listener — catches changes even if DOM is not yet ready
    document.addEventListener('change', e => {
      const el = e.target;
      if (el && el.name === 'autoCompile') {
        SB.autoCompile = el.value === 'on';
        renderAutoCompile();
      }
    });

    // Initial state
    if (!readCurrent()) {
      let n = 0;
      const iv = setInterval(() => { if (readCurrent() || ++n > 30) clearInterval(iv); }, 400);
    }
  }

  // ─── Hook: Compile mode / Syntax check / Error handling radio buttons ───────────
  // These radios use name="compileMode", name="syntaxCheck", name="errorHandling".
  // The app already sends their values to Shiny; we just mirror them in the bar.
  function hookCompileOptions() {
    function readCurrent() {
      let found = 0;
      const cm = document.querySelector('input[name="compileMode"]:checked');
      if (cm) { SB.compileMode = cm.value; found++; }
      const sc = document.querySelector('input[name="syntaxCheck"]:checked');
      if (sc) { SB.syntaxCheck = sc.value; found++; }
      const eh = document.querySelector('input[name="errorHandling"]:checked');
      if (eh) { SB.errorHandling = eh.value; found++; }
      if (found > 0) { renderCompileOptions(); return true; }
      return false;
    }

    // Delegated change listener (same pattern as hookAutoCompile)
    document.addEventListener('change', e => {
      const el = e.target;
      if (!el) return;
      if (el.name === 'compileMode')   { SB.compileMode   = el.value; renderCompileOptions(); }
      if (el.name === 'syntaxCheck')   { SB.syntaxCheck   = el.value; renderCompileOptions(); }
      if (el.name === 'errorHandling') { SB.errorHandling = el.value; renderCompileOptions(); }
    });

    // Poll for initial state (radios may not exist until the dropdown is initialised)
    if (!readCurrent()) {
      let n = 0;
      const iv = setInterval(() => { if (readCurrent() || ++n > 40) clearInterval(iv); }, 350);
    }
  }

  // ─── Clock ────────────────────────────────────────────────────────────────
  function startClock() {
    renderClock();
    setInterval(renderClock, 30000);
  }

  // ─── Tooltip init (Tabler / Bootstrap 5 native) ──────────────────────────
  // All chips have data-bs-toggle="tooltip" + data-bs-placement="top" + title.
  // Bootstrap 5 (bundled with Tabler) auto-initialises [data-bs-toggle=tooltip]
  // elements on page load, but since the bar is injected dynamically we must
  // call getOrCreateInstance() on each chip ourselves after the bar is built.
  function initTooltips() {
    const bar = document.getElementById('mudskipper-status-bar');
    if (!bar || typeof bootstrap === 'undefined' || !bootstrap.Tooltip) return;
    bar.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
      bootstrap.Tooltip.getOrCreateInstance(el, {
        trigger: 'hover',
        boundary: 'window',
      });
    });
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  function init() {
    if (document.getElementById('mudskipper-status-bar')) return;

    const bar = buildBar();
    bar.style.display = 'none'; // start hidden; hookEditorPageVisibility will show it
    document.body.appendChild(bar);

    hookEditorPageVisibility();
    hookShiny();
    hookEditors();
    hookWordCount();
    hookSpellCheck();
    hookCompileStages();
    hookCompileSpinner();
    hookAnnotations();
    hookAutoCompile();
    hookCompileOptions();
    startClock();
    initTooltips();

    renderAll();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    setTimeout(init, 400);
  }

  document.addEventListener('shiny:connected', () => setTimeout(init, 150));

})();
