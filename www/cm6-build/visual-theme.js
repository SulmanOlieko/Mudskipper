import { EditorView } from '@codemirror/view';

export const visualTheme = EditorView.theme({
  "&": {
    fontSize: "14px",
    fontFamily: "Inter, Roboto, sans-serif"
  },
  ".cm-visual-pill": {
    display: "inline-flex",
    alignItems: "center",
    backgroundColor: "var(--bs-gray-200, #f1f3f5)",
    color: "var(--bs-gray-700, #495057)",
    borderRadius: "12px",
    padding: "0 6px",
    margin: "0 2px",
    fontSize: "0.9em",
    fontWeight: "500",
    border: "1px solid var(--bs-gray-300, #dee2e6)",
    userSelect: "none",
    cursor: "default"
  },
  ".cm-visual-brace": {
    color: "var(--bs-gray-500, #adb5bd)",
    margin: "0 1px"
  },
  ".cm-visual-math": {
    display: "inline-block",
    backgroundColor: "var(--bs-blue-lt, #e6f2ff)",
    color: "var(--bs-blue, #0056b3)",
    padding: "2px 6px",
    borderRadius: "4px",
    fontFamily: "Times New Roman, serif",
    fontStyle: "italic"
  },
  ".cm-visual-math-display": {
    display: "block",
    margin: "1em 0",
    textAlign: "center",
    backgroundColor: "var(--bs-blue-lt, #e6f2ff)",
    padding: "10px",
    borderRadius: "6px"
  },
  ".cm-visual-section": {
    fontWeight: "bold",
    color: "var(--bs-primary, #0d6efd)",
    display: "block",
    marginTop: "1.5em",
    marginBottom: "0.5em"
  },
  ".cm-visual-section-part": { fontSize: "1.8em" },
  ".cm-visual-section-chapter": { fontSize: "1.6em" },
  ".cm-visual-section-section": { fontSize: "1.4em", borderBottom: "1px solid var(--bs-gray-200)" },
  ".cm-visual-section-subsection": { fontSize: "1.25em" },
  ".cm-visual-inline-cmd": {
    fontWeight: "bold"
  },
  ".cm-visual-env": {
    display: "block",
    padding: "4px 8px",
    borderLeft: "3px solid var(--bs-primary, #0056b3)",
    backgroundColor: "var(--bs-gray-100, #f8f9fa)",
    color: "var(--bs-gray-600, #6c757d)",
    fontSize: "0.85em",
    marginTop: "0.5em",
    marginBottom: "0.5em",
    fontFamily: "monospace"
  }
});
