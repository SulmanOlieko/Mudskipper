import { WidgetType } from "@codemirror/view";

export class PillWidget extends WidgetType {
  constructor(icon, text) {
    super();
    this.icon = icon;
    this.text = text;
  }
  eq(other) {
    return other.icon === this.icon && other.text === this.text;
  }
  toDOM() {
    let span = document.createElement("span");
    span.className = "cm-visual-pill";
    span.textContent = this.icon + (this.text ? " " + this.text : "");
    return span;
  }
}

export class BraceWidget extends WidgetType {
  constructor(text) {
    super();
    this.text = text;
  }
  eq(other) { return other.text === this.text; }
  toDOM() {
    let span = document.createElement("span");
    span.className = "cm-visual-brace";
    span.textContent = this.text;
    return span;
  }
}

export class MathWidget extends WidgetType {
  constructor(content, isDisplay) {
    super();
    this.content = content;
    this.isDisplay = isDisplay;
  }
  eq(other) {
    return other.content === this.content && other.isDisplay === this.isDisplay;
  }
  toDOM() {
    let span = document.createElement(this.isDisplay ? "div" : "span");
    span.className = this.isDisplay ? "cm-visual-math-display" : "cm-visual-math";
    // We render as fake math text if MathJax is unavailable in this standalone widget
    span.textContent = this.content.trim() || "\\math";
    return span;
  }
}

export class EnvLineWidget extends WidgetType {
  constructor(envName, isBegin) {
    super();
    this.envName = envName;
    this.isBegin = isBegin;
  }
  eq(other) {
    return other.envName === this.envName && other.isBegin === this.isBegin;
  }
  toDOM() {
    let div = document.createElement("div");
    div.className = "cm-visual-env";
    div.textContent = (this.isBegin ? "begin: " : "end: ") + this.envName;
    return div;
  }
}
