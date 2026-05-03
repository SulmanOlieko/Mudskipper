import { EditorView } from '@codemirror/view'
import { Diagnostic, lintGutter, linter } from '@codemirror/lint'

export const lintSourceConfig = {
  delay: 800, 
  markerFilter(diagnostics: readonly Diagnostic[]) {
    return diagnostics.filter(d => d.severity === 'error' || d.severity === 'warning')
  },
  tooltipFilter() {
    return []
  }
}

export const renderMessage = (diagnostic: Diagnostic): HTMLElement => {
  const dom = document.createElement('div')
  dom.className = 'ol-cm-diagnostic-message'
  
  const icon = document.createElement('span')
  icon.className = `cm-lint-icon cm-lint-icon-${diagnostic.severity}`
  dom.appendChild(icon)
  
  const content = document.createElement('div')
  content.className = 'cm-lint-content'
  
  const text = document.createElement('span')
  text.className = 'cm-lint-text'
  text.textContent = typeof diagnostic.message === 'string' ? diagnostic.message : 'Error'
  content.appendChild(text)
  
  if ((diagnostic as any).ruleId) {
    const rule = document.createElement('div')
    rule.className = 'cm-lint-rule'
    rule.textContent = (diagnostic as any).ruleId
    content.appendChild(rule)
  }
  
  dom.appendChild(content)
  return dom
}

export const lintTheme = [
  EditorView.baseTheme({
    '.cm-gutter-lint': {
      width: '12px',
      order: -1, 
    },
    '.cm-lint-marker': {
      width: '8px',
      height: '8px',
      borderRadius: '50%',
      margin: '4px auto',
      cursor: 'pointer',
    },
    '.cm-lint-marker-error': { backgroundColor: '#e53935' },
    '.cm-lint-marker-warning': { backgroundColor: '#fb8c00' },
    '.cm-lint-marker-info': { backgroundColor: '#1e88e5' },
    
    '.ol-cm-diagnostic-message': {
      padding: '6px 10px',
      display: 'flex',
      alignItems: 'start',
      gap: '10px',
      maxWidth: '400px',
      wordBreak: 'break-word',
      fontSize: '12px',
      lineHeight: '1.5',
    },
    '.cm-lint-content': {
      display: 'flex',
      flexDirection: 'column',
    },
    '.cm-lint-rule': {
      fontSize: '10px',
      opacity: '0.6',
      marginTop: '2px',
      fontFamily: 'monospace',
    },
    
    '.cm-tooltip-lint': {
      backgroundColor: 'var(--tblr-bg-surface, #fff)',
      border: '1px solid var(--tblr-border-color, #dee2e6)',
      borderRadius: '4px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
      color: '#1e1e1e !important', // Force black text in tooltips for Light Mode
      overflow: 'hidden',
    },
    '&dark .cm-tooltip-lint': {
      backgroundColor: 'var(--tblr-bg-surface, #2c3645)',
      color: '#f6f8fb !important', // Force white text in tooltips for Dark Mode
      borderColor: 'rgba(255,255,255,0.1)',
    },
    
    // Inline diagnostic styles
    '.cm-lintRange-error': {
      backgroundImage: "url('data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"6\" height=\"3\"><path d=\"M0 3 L3 0 L6 3\" fill=\"none\" stroke=\"%23e53935\" stroke-width=\"1\"/></svg>')",
      backgroundRepeat: 'repeat-x',
      backgroundPosition: 'bottom left',
      paddingBottom: '1px',
      backgroundColor: 'rgba(229, 57, 53, 0.12)',
    },
    '.cm-lintRange-warning': {
      backgroundImage: "url('data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"6\" height=\"3\"><path d=\"M0 3 L3 0 L6 3\" fill=\"none\" stroke=\"%23fb8c00\" stroke-width=\"1\"/></svg>')",
      backgroundRepeat: 'repeat-x',
      backgroundPosition: 'bottom left',
      paddingBottom: '1px',
      backgroundColor: 'rgba(251, 140, 0, 0.12)',
    },
    '.cm-lintRange-info': {
        backgroundColor: 'rgba(30, 136, 229, 0.06)',
    }
  })
]

export { lintGutter }
