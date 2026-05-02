import { EditorView } from '@codemirror/view'
import { Compartment, TransactionSpec } from '@codemirror/state'
import { syntaxHighlighting } from '@codemirror/language'
import { classHighlighter } from './class-highlighter'
import classNames from 'classnames'

type FontFamily = string
type LineHeight = string

const optionsThemeConf = new Compartment()

type Options = {
  fontSize?: number
  fontFamily?: FontFamily
  lineHeight?: LineHeight
  activeOverallTheme?: string
}

export const theme = (options: Options) => [
  baseTheme,
  staticTheme,
  /**
   * Syntax highlighting, using a highlighter which maps tags to class names.
   */
  syntaxHighlighting(classHighlighter),
  optionsThemeConf.of(createThemeFromOptions(options)),
]

export const setOptionsTheme = (options: Options): TransactionSpec => {
  return {
    effects: optionsThemeConf.reconfigure(createThemeFromOptions(options)),
  }
}

const createThemeFromOptions = ({
  fontSize = 12,
  fontFamily = 'monaco',
  lineHeight = 'normal',
  activeOverallTheme = 'light',
}: Options) => {
  const fontSizeCSS = `${fontSize}px`
  const lineHeightCSS = lineHeight === 'compact' ? '1.33' : lineHeight === 'wide' ? '1.8' : '1.6'

  return [
    EditorView.editorAttributes.of({
      class: classNames(
        activeOverallTheme === 'dark'
          ? 'overall-theme-dark'
          : 'overall-theme-light'
      ),
      style: Object.entries({
        '--font-size': fontSizeCSS,
        '--source-font-family': fontFamily,
        '--line-height': lineHeightCSS,
        '--editor-toolbar-bg': activeOverallTheme === 'dark' ? '#2c3645' : '#f8f9fa',
        '--toolbar-btn-color': activeOverallTheme === 'dark' ? '#f6f8fb' : '#1e1e1e',
        '--toolbar-dropdown-divider-color': activeOverallTheme === 'dark' ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)',
        '--border-divider-dark': activeOverallTheme === 'dark' ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)',
        // Tabler overrides to prevent theme bleeding
        '--tblr-bg-surface-secondary': activeOverallTheme === 'dark' ? '#2c3645' : '#f1f5f9',
        '--tblr-border-color': activeOverallTheme === 'dark' ? '#3c4043' : '#dee2e6',
        '--tblr-muted': activeOverallTheme === 'dark' ? '#9aa0a6' : '#6c757d',
        '--tblr-body-color': activeOverallTheme === 'dark' ? '#f6f8fb' : '#1e1e1e',
        '--tblr-bg-surface': activeOverallTheme === 'dark' ? '#1e2124' : '#fff',
        // Bootstrap overrides
        '--bs-body-bg': activeOverallTheme === 'dark' ? '#1e2124' : '#fff',
        '--bs-body-color': activeOverallTheme === 'dark' ? '#f6f8fb' : '#1e1e1e',
        '--bs-tertiary-bg': activeOverallTheme === 'dark' ? '#2c3645' : '#f8f9fa',
        '--bs-border-color': activeOverallTheme === 'dark' ? '#3c4043' : '#dee2e6',
      })
        .map(([key, value]) => `${key}: ${value}`)
        .join(';'),
    }),
  ]
}

/**
 * Base styles that can have &dark and &light variants
 */
const baseTheme = EditorView.baseTheme({
  '&light.cm-editor': {
    colorScheme: 'light',
    backgroundColor: '#fff',
    color: '#1e1e1e',
  },
  '&dark.cm-editor': {
    colorScheme: 'dark',
    backgroundColor: '#1e2124',
    color: '#f6f8fb',
  },
  '.cm-content': {
    fontSize: 'var(--font-size)',
    fontFamily: 'var(--source-font-family)',
    lineHeight: 'var(--line-height)',
  },
  '.cm-cursor-primary': {
    fontSize: 'var(--font-size)',
    fontFamily: 'var(--source-font-family)',
    lineHeight: 'var(--line-height)',
  },
  '.cm-gutters': {
    fontSize: 'var(--font-size)',
    lineHeight: 'var(--line-height)',
  },
  '.cm-tooltip': {
    fontSize: 'var(--font-size)',
  },
  '.cm-panel': {
    fontSize: 'var(--font-size)',
  },
  '.cm-foldGutter .cm-gutterElement > span': {
    height: 'calc(var(--font-size) * var(--line-height))',
  },
  '.cm-lineNumbers': {
    fontFamily: 'var(--source-font-family)',
  },
  '.cm-specialChar': {
    color: 'red',
    backgroundColor: 'rgba(255, 0, 0, 0.1)',
  },
  '.cm-widgetBuffer': {
    height: '1.3em',
  },
  '.cm-snippetFieldPosition': {
    display: 'inline-block',
    height: '1.3em',
  },
  // style the gutter fold button on hover
  '&dark .cm-foldGutter .cm-gutterElement > span:hover': {
    boxShadow: '0 1px 1px rgba(255, 255, 255, 0.2)',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  '&light .cm-foldGutter .cm-gutterElement > span:hover': {
    borderColor: 'rgba(0, 0, 0, 0.3)',
    boxShadow: '0 1px 1px rgba(255, 255, 255, 0.7)',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
})

/**
 * Theme styles that don't depend on settings.
 */
const staticTheme = EditorView.theme({
  // make the editor fill the available height
  '&': {
    height: '100%',
    textRendering: 'optimizeSpeed',
    fontVariantNumeric: 'slashed-zero',
  },
  // remove the outline from the focused editor
  '&.cm-editor.cm-focused:not(:focus-visible)': {
    outline: 'none',
  },
  '.cm-selectionLayer': {
    zIndex: -10,
  },
  // remove the right-hand border from the gutter
  // ensure the gutter doesn't shrink
  '.cm-gutters': {
    borderRight: 'none',
    flexShrink: 0,
  },
  // style the gutter fold button
  '.cm-foldGutter .cm-gutterElement > span': {
    border: '1px solid transparent',
    borderRadius: '3px',
    display: 'inline-flex',
    flexDirection: 'column',
    justifyContent: 'center',
    color: 'rgba(109, 109, 109, 0.7)',
  },
  // reduce the padding around line numbers
  '.cm-lineNumbers .cm-gutterElement': {
    padding: '0',
    userSelect: 'none',
  },
  // make cursor visible with reduced opacity when the editor is not focused
  '&:not(.cm-focused) > .cm-scroller > .cm-cursorLayer .cm-cursor': {
    display: 'block',
    opacity: 0.2,
  },
  // make the cursor wider, and use the themed color
  '.cm-cursor, .cm-dropCursor': {
    borderWidth: '2px',
    marginLeft: '-1px', // half the border width
    borderLeftColor: 'inherit',
  },
  // remove border from hover tooltips (e.g. cursor highlights)
  '.cm-tooltip-hover': {
    border: 'none',
  },
  // use the same style as Ace for snippet fields
  '.cm-snippetField': {
    background: 'rgba(194, 193, 208, 0.09)',
    border: '1px dotted rgba(211, 208, 235, 0.62)',
  },
  // style the fold placeholder
  '.cm-foldPlaceholder': {
    boxSizing: 'border-box',
    display: 'inline-block',
    height: '11px',
    width: '1.8em',
    marginTop: '-2px',
    verticalAlign: 'middle',
    backgroundImage:
      'url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAAJCAYAAADU6McMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAJpJREFUeNpi/P//PwOlgAXGYGRklAVSokD8GmjwY1wasKljQpYACtpCFeADcHVQfQyMQAwzwAZI3wJKvCLkfKBaMSClBlR7BOQikCFGQEErIH0VqkabiGCAqwUadAzZJRxQr/0gwiXIal8zQQPnNVTgJ1TdawL0T5gBIP1MUJNhBv2HKoQHHjqNrA4WO4zY0glyNKLT2KIfIMAAQsdgGiXvgnYAAAAASUVORK5CYII="),url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAA3CAYAAADNNiA5AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAACJJREFUeNpi+P//fxgTAwPDBxDxD078RSX+YeEyDFMCIMAAI3INmXiwf2YAAAAASUVORK5CYII=")',
    backgroundRepeat: 'no-repeat, repeat-x',
    backgroundPosition: 'center center, top left',
    color: 'transparent',
    border: '1px solid black',
    borderRadius: '2px',
  },
})
