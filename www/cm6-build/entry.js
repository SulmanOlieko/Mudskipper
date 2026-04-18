import { EditorState } from "@codemirror/state";
import { EditorView, keymap, lineNumbers, highlightActiveLine, highlightActiveLineGutter } from "@codemirror/view";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { LRLanguage, LanguageSupport, syntaxHighlighting, defaultHighlightStyle } from "@codemirror/language";
import { parser } from "./lezer-latex/latex.mjs";
import { visual } from "@/features/source-editor/extensions/visual/visual.ts";

// Define a basic language support for LaTeX using our generated parser
const latexLanguage = LRLanguage.define({
  parser: parser.configure({
    props: []
  }),
  languageData: {
    commentTokens: {line: "%"}
  }
});
const latex = new LanguageSupport(latexLanguage);

export function initVisualEditor(parentElement, initialDoc, onChange) {
  const state = EditorState.create({
    doc: initialDoc,
    extensions: [
      lineNumbers(),
      highlightActiveLineGutter(),
      history(),
      latex,
      syntaxHighlighting(defaultHighlightStyle),
      visual({ visual: true, previewByPath: (path) => null }),
      EditorView.lineWrapping,
      keymap.of([
        ...defaultKeymap,
        ...historyKeymap
      ]),
      EditorView.updateListener.of((update) => {
        if (update.docChanged && onChange) {
          onChange(update.state.doc.toString());
        }
      })
    ]
  });

  const view = new EditorView({
    state,
    parent: parentElement
  });
  
  return view;
}

export function setEditorContent(view, content) {
  const current = view.state.doc.toString();
  if (current !== content) {
    view.dispatch({
      changes: {from: 0, to: view.state.doc.length, insert: content}
    });
  }
}
