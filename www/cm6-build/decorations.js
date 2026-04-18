import { StateField, Range } from "@codemirror/state";
import { Decoration } from "@codemirror/view";
import { syntaxTree } from "@codemirror/language";
import { PillWidget, EnvLineWidget, MathWidget, BraceWidget } from "./visual-widgets.js";

// Helper to determine if we should decorate (don't fold if cursor is inside)
function shouldDecorate(state, from, to) {
  const selection = state.selection.main;
  // If cursor intersects, don't fold.
  return !(selection.from <= to && selection.to >= from);
}

export const visualDecorations = StateField.define({
  create(state) {
    return buildDecorations(state);
  },
  update(value, tr) {
    if (tr.docChanged || tr.selection) {
      return buildDecorations(tr.state);
    }
    return value;
  },
  provide: f => EditorView.decorations.from(f)
});

import { EditorView } from "@codemirror/view";

function buildDecorations(state) {
  let widgets = [];
  
  syntaxTree(state).iterate({
    enter: (nodeRef) => {
      // Hide comments entirely if not selected
      if (nodeRef.name === "Comment" && shouldDecorate(state, nodeRef.from, nodeRef.to)) {
        widgets.push(Decoration.replace({}).range(nodeRef.from, nodeRef.to));
        return false;
      }

      // Cite tags
      if (nodeRef.name === "Cite" && shouldDecorate(state, nodeRef.from, nodeRef.to)) {
        widgets.push(Decoration.replace({
          widget: new PillWidget("📚", "cite")
        }).range(nodeRef.from, nodeRef.to));
        return false;
      }

      // Ref tags
      if (nodeRef.name === "Ref" && shouldDecorate(state, nodeRef.from, nodeRef.to)) {
        widgets.push(Decoration.replace({
          widget: new PillWidget("🏷", "ref")
        }).range(nodeRef.from, nodeRef.to));
        return false;
      }
      
      // Inline Math
      if (nodeRef.name === "DollarMath" && shouldDecorate(state, nodeRef.from, nodeRef.to)) {
        const text = state.sliceDoc(nodeRef.from, nodeRef.to).replace(/(^\\?[$]+)|([$]+\\?$)/g, '');
        widgets.push(Decoration.replace({
          widget: new MathWidget(text, false)
        }).range(nodeRef.from, nodeRef.to));
        return false;
      }

      // Display Math
      if ((nodeRef.name === "BracketMath" || nodeRef.name === "EquationEnvironment") 
          && shouldDecorate(state, nodeRef.from, nodeRef.to)) {
        let text = state.sliceDoc(nodeRef.from, nodeRef.to);
        widgets.push(Decoration.replace({
          widget: new MathWidget(text, true),
          block: true
        }).range(nodeRef.from, nodeRef.to));
        return false;
      }

      // Environment Begin/End
      if (nodeRef.name === "BeginEnv" && shouldDecorate(state, nodeRef.from, nodeRef.to)) {
        const text = state.sliceDoc(nodeRef.from, nodeRef.to);
        const match = text.match(/\\begin{([^}]+)}/);
        const envName = match ? match[1] : "env";
        if (!["document"].includes(envName)) {
           widgets.push(Decoration.replace({
             widget: new EnvLineWidget(envName, true),
             block: true
           }).range(nodeRef.from, Math.min(state.doc.length, nodeRef.to + (state.doc.sliceString(nodeRef.to, nodeRef.to + 1) === '\\n' ? 1 : 0))));
        }
      }
      if (nodeRef.name === "EndEnv" && shouldDecorate(state, nodeRef.from, nodeRef.to)) {
        const text = state.sliceDoc(nodeRef.from, nodeRef.to);
        const match = text.match(/\\end{([^}]+)}/);
        const envName = match ? match[1] : "env";
        if (!["document"].includes(envName)) {
           widgets.push(Decoration.replace({
             widget: new EnvLineWidget(envName, false),
             block: true
           }).range(nodeRef.from, Math.min(state.doc.length, nodeRef.to + (state.doc.sliceString(nodeRef.to, nodeRef.to + 1) === '\\n' ? 1 : 0))));
        }
      }

      // Sectioning commands (just styling the headers, keeping text editable)
      // The grammar creates SectioningCommand with children. We will mark them with classes via line decorators or mark decorators
      if (["Chapter", "Section", "SubSection", "SubSubSection"].includes(nodeRef.name)) {
        const cls = "cm-visual-section cm-visual-section-" + nodeRef.name.toLowerCase();
        widgets.push(Decoration.line({ class: cls }).range(nodeRef.from));
      }
    }
  });

  return Decoration.set(widgets, true);
}
