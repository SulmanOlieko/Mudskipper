// Mudskipper Visual Editor Bundle Loaded (v5 - SyncTeX Fixed)
import {
  EditorView,
  keymap,
  lineNumbers,
  highlightActiveLineGutter,
  rectangularSelection,
  crosshairCursor,
  dropCursor,
  tooltips,
  Decoration,
  DecorationSet,
} from "@codemirror/view";
import { lintGutter } from "@codemirror/lint";
import { EditorState, Compartment, StateEffect, StateField } from "@codemirror/state";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { foldGutter, indentOnInput, indentUnit } from "@codemirror/language";
import i18n from '@/infrastructure/i18n';
import { latexLinter } from "@/features/source-editor/languages/latex/linter/latex-linter.ts";
// import { bibtexLintSource } from "@/features/source-editor/languages/bibtex/linting.ts";
// import { bibtex } from "@/features/source-editor/languages/bibtex/index.ts";

// Overleaf visual extensions — the full pipeline
import { visual, sourceOnly } from "@/features/source-editor/extensions/visual/visual.ts";
import { lintTheme } from "@/features/source-editor/extensions/annotations.ts";
import { language } from "@/features/source-editor/extensions/language.ts";
import { theme } from "@/features/source-editor/extensions/theme.ts";
import { editable } from "@/features/source-editor/extensions/editable.ts";
import { drawSelection } from "@/features/source-editor/extensions/draw-selection.ts";
import { highlightSpecialChars } from "@/features/source-editor/extensions/highlight-special-chars.ts";
import { highlightActiveLine } from "@/features/source-editor/extensions/highlight-active-line.ts";
import { lineWrappingIndentation } from "@/features/source-editor/extensions/line-wrapping-indentation.ts";
import { bracketMatching, bracketSelection } from "@/features/source-editor/extensions/bracket-matching.ts";
import { inlineBackground } from "@/features/source-editor/extensions/inline-background.ts";
import { verticalOverflow } from "@/features/source-editor/extensions/vertical-overflow.ts";
import { emptyLineFiller } from "@/features/source-editor/extensions/empty-line-filler.ts";
import { filterCharacters } from "@/features/source-editor/extensions/filter-characters.ts";
import { effectListeners } from "@/features/source-editor/extensions/effect-listeners.ts";
import { geometryChangeEvent } from "@/features/source-editor/extensions/geometry-change-event.ts";
import { keymaps } from "@/features/source-editor/extensions/keymaps.ts";

const darkThemeConf = new Compartment();
export const BUNDLE_VERSION = 'v5';

// --- SPELLCHECK DECORATIONS ---
const addSpellcheckEffect = StateEffect.define();
const clearSpellcheckEffect = StateEffect.define();

const spellcheckField = StateField.define({
  create() {
    return Decoration.none;
  },
  update(decorations, tr) {
    decorations = decorations.map(tr.changes);
    for (const effect of tr.effects) {
      if (effect.is(addSpellcheckEffect)) {
        const deco = Decoration.mark({ class: 'cm-misspelled' });
        const ranges = effect.value.map(t => deco.range(t.from, t.to));
        decorations = decorations.update({ add: ranges, sort: true });
      } else if (effect.is(clearSpellcheckEffect)) {
        decorations = Decoration.none;
      }
    }
    return decorations;
  },
  provide: f => EditorView.decorations.from(f)
});

export function initVisualEditor(parentElement, initialDoc, onChange, settings = {}) {
  const isVisual = true;
  const { 
    fontSize = 14, 
    theme: activeOverallTheme = 'light' 
  } = settings;


  const state = EditorState.create({
    doc: initialDoc,
    extensions: [
      // Core editor features
      // --- 1. CORE SYNC EVENTS ---
      EditorView.domEventHandlers({
        dblclick: (event, view) => {
          const pos = view.posAtCoords({ x: event.clientX, y: event.clientY });
          if (pos != null) {
            const line = view.state.doc.lineAt(pos);
            const lineNum = line.number; // CM6 is 1-indexed
            const columnNum = pos - line.from + 1; // 1-indexed
            if (window.Shiny) {
              Shiny.setInputValue('editorSyncClick', {
                line: lineNum,
                column: columnNum,
                nonce: Math.random()
              }, {priority: 'event'});
            }
          }
        }
      }),

      // --- 2. CORE FEATURES ---
      lineNumbers(),
      highlightSpecialChars(isVisual),
      history({ newGroupDelay: 250 }),
      foldGutter({
        openText: '▾',
        closedText: '▸',
      }),
      drawSelection(),
      EditorState.allowMultipleSelections.of(true),
      EditorView.lineWrapping,

      // Source-only label (hidden in visual mode)
      sourceOnly(
        isVisual,
        EditorView.contentAttributes.of({ 'aria-label': 'Source Editor editing' })
      ),

      // Editing helpers
      indentOnInput(),
      lineWrappingIndentation(isVisual),
      bracketMatching(),
      bracketSelection(),
      rectangularSelection(),
      crosshairCursor(),
      dropCursor(),

      // Tooltips
      tooltips({
        parent: parentElement,
        tooltipSpace(view) {
          const { top, bottom } = view.scrollDOM.getBoundingClientRect();
          return { top, left: 0, bottom, right: window.innerWidth };
        },
      }),

      // Keymaps
      keymaps,
      filterCharacters(),

      // Phrases for non-React widgets
      EditorState.phrases.of({
        "sorry_your_table_cant_be_displayed_at_the_moment": "Sorry, your table can't be displayed at the moment",
        "this_could_be_because_we_cant_support_some_elements_of_the_table": "This could be because we can't support some elements of the table",
        "view_code": "View code",
        "column_width_is_custom_click_to_resize": "Column width is custom, click to resize",
        "column_width_is_x_click_to_resize": "Column width is $width, click to resize"
      }),

      // Language support — loads Overleaf's configured LaTeX parser
      language('document.tex'),
      indentUnit.of('    '),
      lintTheme,
      lintGutter({ hoverTime: 0 }),

      // Theme
      theme({
        fontSize: fontSize,
        fontFamily: "'Source Code Pro', monospace",
        lineHeight: 'normal',
        activeOverallTheme: activeOverallTheme,
      }),
      
      darkThemeConf.of(activeOverallTheme === 'dark' ? EditorView.darkTheme.of(true) : []),

      // Editability
      editable(),

      // Empty line filler (for tracked changes highlighting)
      emptyLineFiller(),

      // === THE VISUAL EDITOR ===
      visual({
        visual: isVisual,
        previewByPath: (path) => {
          if (!path) return null;
          const ext = path.split('.').pop() || '';
          const filename = path.split('/').pop() || path;
          const cleanPath = path.replace(/^\/+/, '');
          
          let foundPath = cleanPath;
          const fileList = window.projectFileList || [];
          
          // Strategy 1: Exact match
          const exactMatch = fileList.find(f => f.toLowerCase() === cleanPath.toLowerCase());
          
          if (exactMatch) {
            foundPath = exactMatch;
          } else {
            // Strategy 2: Recursive Search
            const fuzzyMatch = fileList.find(f => {
              const fName = f.split('/').pop();
              return fName === filename;
            });
            
            if (fuzzyMatch) {
              foundPath = fuzzyMatch;
            }
          }

          const basePath = window.activeProjectPath || '/project/';
          const url = (basePath.endsWith('/') ? basePath : basePath + '/') + foundPath;
          
          return {
            extension: ext.toLowerCase(),
            url: url,
          };
        },
      }),

      // Source editor features (disabled in visual mode via sourceOnly)
      verticalOverflow(),
      highlightActiveLine(isVisual),
      highlightActiveLineGutter(),
      inlineBackground(isVisual),

      // Exception handling
      EditorView.exceptionSink.of((exception) => {
        console.error('CodeMirror exception:', exception);
      }),

      // Infrastructure
      effectListeners(),
      geometryChangeEvent(),

      // Spellcheck field
      spellcheckField,

      // Document change listener
      EditorView.updateListener.of((update) => {
        if (update.docChanged && onChange) {
          onChange(update.state.doc.toString());
        }
        
        // --- CURSOR TRACKING FOR OUTLINE ---
        if (update.selectionSet && window.Shiny && Shiny.setInputValue) {
          const pos = update.state.selection.main.head;
          const line = update.state.doc.lineAt(pos);
          Shiny.setInputValue('cursorPosition', {
            row: line.number - 1,
            column: pos - line.from
          }, {priority: 'event'});
        }
      }),

      // Phrases for non-React widgets (Preamble, etc.)
      EditorState.phrases.of({
        "show_document_preamble": "Show document preamble",
        "hide_document_preamble": "Hide document preamble",
        "expand": "Expand",
        "learn_more": "Learn more",
      }),
    ],
  });

  const view = new EditorView({
    state,
    parent: parentElement,
  });

  return view;
}

export function setEditorContent(view, content) {
  const current = view.state.doc.toString();
  // Normalize \r\n to \n for comparison to avoid full document replace on server echo
  if (current.replace(/\r\n/g, '\n') !== content.replace(/\r\n/g, '\n')) {
    view.dispatch({
      changes: { from: 0, to: view.state.doc.length, insert: content },
    });
  }
}

export function goToLine(view, line, column, selectText) {
  if (!view || typeof line !== 'number') return;
  
  const cmLine = line + 1; // Ace 0-indexed to CM6 1-indexed
  if (cmLine < 1 || cmLine > view.state.doc.lines) return;
  
  const lineObj = view.state.doc.line(cmLine);
  let from = lineObj.from;
  let to = lineObj.from;
  
  // Precision 1: Text matching (highest priority)
  if (selectText && selectText.length > 0) {
      const lineText = lineObj.text;
      const index = lineText.toLowerCase().indexOf(selectText.toLowerCase());
      if (index !== -1) {
          from = lineObj.from + index;
          to = from + selectText.length;
      } else if (column != null && column > 0) {
          // Fallback to column if text not found
          from = Math.min(lineObj.from + (column - 1), lineObj.to);
          to = from;
      }
  } else if (column != null && column > 0) {
      // Precision 2: Column positioning (SyncTeX columns are 1-indexed)
      from = Math.min(lineObj.from + (column - 1), lineObj.to);
      to = from;
  }
  
  view.dispatch({
    selection: { anchor: from, head: to },
    scrollIntoView: true,
    userEvent: 'select'
  });
  view.focus();
}


export function setOptionsTheme(settings = {}) {
  const { fontSize = 14, theme: activeOverallTheme = 'light' } = settings;
  const baseResult = setBaseOptionsTheme({
    fontSize: fontSize,
    fontFamily: "'Source Code Pro', monospace",
    lineHeight: 'normal',
    activeOverallTheme: activeOverallTheme,
  });
  
  const darkEffect = darkThemeConf.reconfigure(activeOverallTheme === 'dark' ? EditorView.darkTheme.of(true) : []);
  
  // Return a flat array of effects
  if (Array.isArray(baseResult.effects)) {
    return [...baseResult.effects, darkEffect];
  } else {
    return [baseResult.effects, darkEffect];
  }
}

export function getCursorPosition(view) {
  if (!view) return { row: 0, column: 0 };
  const pos = view.state.selection.main.head;
  const line = view.state.doc.lineAt(pos);
  return {
    row: line.number - 1,
    column: pos - line.from
  };
}

export function setCursorPosition(view, row, column = 0) {
  if (!view) return;
  const cmLine = row + 1;
  if (cmLine < 1 || cmLine > view.state.doc.lines) return;
  
  const lineObj = view.state.doc.line(cmLine);
  const pos = Math.min(lineObj.from + column, lineObj.to);
  
  view.dispatch({
    selection: { anchor: pos },
    scrollIntoView: true
  });
}

/**
 * Update misspelled decorations based on worker results
 */
export function updateSpellcheckDecorations(view, typos) {
  if (!view) return;
  
  const effects = [clearSpellcheckEffect.of()];
  
  if (typos && typos.length > 0) {
    const ranges = typos.map(t => {
      // Ace uses row/col, we need to convert to absolute pos
      try {
        const line = view.state.doc.line(t.row + 1);
        const from = line.from + t.col;
        const to = from + t.len;
        return { from, to };
      } catch (e) {
        return null;
      }
    }).filter(r => r !== null);
    
    if (ranges.length > 0) {
      effects.push(addSpellcheckEffect.of(ranges));
    }
  }
  
  view.dispatch({ effects });
}

/**
 * Get count of misspelled words
 */
export function getSpellcheckErrorCount(view) {
  if (!view) return 0;
  const field = view.state.field(spellcheckField, false);
  if (!field) return 0;
  let count = 0;
  field.between(0, view.state.doc.length, () => {
    count++;
  });
  return count;
}

/**
 * Insert text at current cursor position
 */
export function insertText(view, text) {
  if (!view) return;
  const mainSelection = view.state.selection.main;
  view.dispatch({
    changes: { from: mainSelection.from, to: mainSelection.to, insert: text },
    selection: { anchor: mainSelection.from + text.length },
    scrollIntoView: true
  });
  view.focus();
}


/**
 * Run the robust linter standalone (for Ace)
 */
export async function runStandaloneLinter(text, fileType) {
  if (fileType === 'latex' || fileType === 'tex') {
    const state = EditorState.create({ doc: text });
    const mockView = { state, dispatch: () => {} };
    return await latexLinter(mockView);
  } /* else if (fileType === 'bibtex' || fileType === 'bib') {
    const state = EditorState.create({
      doc: text,
      extensions: [bibtex()]
    });
    const mockView = { state };
    return bibtexLintSource(mockView);
  } */
  return [];
}

import { setOptionsTheme as setBaseOptionsTheme } from "@/features/source-editor/extensions/theme.ts";
