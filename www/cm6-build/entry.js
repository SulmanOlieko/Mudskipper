// Mudskipper Visual Editor Bundle Loaded (v2)
import { EditorState } from "@codemirror/state";
import {
  EditorView,
  keymap,
  lineNumbers,
  highlightActiveLineGutter,
  rectangularSelection,
  crosshairCursor,
  dropCursor,
  tooltips,
} from "@codemirror/view";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { foldGutter, indentOnInput, indentUnit } from "@codemirror/language";

// Overleaf visual extensions — the full pipeline
import { visual, sourceOnly } from "@/features/source-editor/extensions/visual/visual.ts";
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

export function initVisualEditor(parentElement, initialDoc, onChange) {
  const isVisual = true;

  const state = EditorState.create({
    doc: initialDoc,
    extensions: [
      // Core editor features
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
        parent: document.body,
        tooltipSpace(view) {
          const { top, bottom } = view.scrollDOM.getBoundingClientRect();
          return { top, left: 0, bottom, right: window.innerWidth };
        },
      }),

      // Keymaps
      keymaps,
      filterCharacters(),

      // Language support — loads Overleaf's configured LaTeX parser
      language('document.tex'),
      indentUnit.of('    '),

      // Theme
      theme({
        fontSize: 14,
        fontFamily: "'Source Code Pro', monospace",
        lineHeight: 'normal',
        activeOverallTheme: 'light',
      }),

      // Editability
      editable(),

      // Empty line filler (for tracked changes highlighting)
      emptyLineFiller(),

      // === THE VISUAL EDITOR ===
      // This loads the full Overleaf visual pipeline:
      // - visualTheme (Noto Serif font, proper spacing, CSS)
      // - visualHighlightStyle (syntax highlighting for visual mode)
      // - atomicDecorations (preamble, environments, math, graphics, lists, etc.)
      // - markDecorations (headings, formatting, colors, etc.)
      // - visualKeymap (Enter for list items, Tab for indent, etc.)
      // - commandTooltip
      // - pasteHtml (paste HTML as LaTeX)
      // - tableGeneratorTheme
      // - showContentWhenParsed (delayed content display)
      visual({
        visual: isVisual,
        previewByPath: (path) => {
          if (!path) return null;
          const ext = path.split('.').pop() || '';
          const filename = path.split('/').pop() || path;
          const cleanPath = path.replace(/^\/+/, '');
          
          let foundPath = cleanPath;
          const fileList = window.projectFileList || [];
          
          // Strategy 1: Exact match (case insensitive for extension)
          const exactMatch = fileList.find(f => f.toLowerCase() === cleanPath.toLowerCase());
          
          if (exactMatch) {
            foundPath = exactMatch;
          } else {
            // Strategy 2: Recursive Search (Find file anywhere in the project)
            // Look for a file that matches the filename exactly
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

      // Document change listener
      EditorView.updateListener.of((update) => {
        if (update.docChanged && onChange) {
          onChange(update.state.doc.toString());
        }
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
