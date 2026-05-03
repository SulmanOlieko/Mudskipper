import { EditorView, WidgetType } from '@codemirror/view'
import { loadMathJax } from '@/features/mathjax/load-mathjax'
import { placeSelectionInsideBlock } from '../selection'

/** Schedule fn in an idle callback if available, else fall back to setTimeout. */
function scheduleIdle(
  fn: () => void,
  timeout = 2000
): void {
  if (typeof requestIdleCallback !== 'undefined') {
    requestIdleCallback(() => fn(), { timeout })
  } else {
    setTimeout(fn, 0)
  }
}

/** Global cache for rendered KaTeX elements and their labels to prevent re-rendering identical math. */
interface CachedMath {
  svg: HTMLElement
  label: string | null
}
const mathCache = new Map<string, CachedMath>()

/** Global cache for image loading states to prevent redundant fetches. */
const imageCache = new Map<string, HTMLImageElement>()

export class MathWidget extends WidgetType {
  destroyed = false
  cachedHeight: number | undefined = undefined
  private rendering = false // guard against concurrent MathJax calls

  constructor(
    public math: string,
    public displayMode: boolean,
    public preamble?: string
  ) {
    super()
  }

  toDOM(view: EditorView) {
    this.destroyed = false
    const element = document.createElement(this.displayMode ? 'div' : 'span')
    element.classList.add('ol-cm-math')
    if (this.displayMode) {
      element.addEventListener('mouseup', event => {
        event.preventDefault()
        view.dispatch(placeSelectionInsideBlock(view, event as MouseEvent))
      })
    }

    // Check cache first
    const cacheKey = `${this.math}-${this.displayMode}`
    const cached = mathCache.get(cacheKey)
    if (cached) {
      element.appendChild(cached.svg.cloneNode(true))
      if (cached.label && this.displayMode) {
        const badge = document.createElement('div')
        badge.className = 'ol-cm-math-label-badge'
        badge.textContent = `eq: ${cached.label}`
        element.appendChild(badge)
      }
      element.style.height = 'auto'
      return element
    }

    // Show a placeholder while loading
    element.textContent = this.displayMode ? 'Rendering...' : '...'
    
    this.renderMath(element).then(() => {
        view.requestMeasure()
    })

    return element
  }

  eq(widget: MathWidget) {
    return (
      widget.math === this.math &&
      widget.displayMode === this.displayMode &&
      widget.preamble === this.preamble
    )
  }

  updateDOM(element: HTMLElement, view: EditorView) {
    this.destroyed = false
    // Skip if a render is already in flight to avoid thrashing MathJax.
    if (this.rendering) return true
    scheduleIdle(() => {
      this.renderMath(element)
        .catch(() => {
          element.classList.add('ol-cm-math-error')
        })
        .finally(() => {
          view.requestMeasure()
        })
    })
    return true
  }

  ignoreEvent(event: Event) {
    // always enable mouseup to release the decorations
    if (event.type === 'mouseup') {
      return false
    }

    // inline math needs mousedown to set the selection
    if (!this.displayMode && event.type === 'mousedown') {
      return false
    }

    // ignore other events
    return true
  }

  destroy() {
    this.destroyed = true
  }

  get estimatedHeight() {
    return this.cachedHeight ?? this.math.split('\n').length * 40
  }

  coordsAt(element: HTMLElement) {
    return element.getBoundingClientRect()
  }

  async renderMath(element: HTMLElement) {
    if (this.rendering) return
    this.rendering = true
    
    try {
      // Extract \label{...} if present
      let mathToRender = this.math
      let labelName: string | null = null
      const labelMatch = mathToRender.match(/\\label\{([^}]+)\}/)
      if (labelMatch) {
        labelName = labelMatch[1]
        // Remove the label from the string we pass to KaTeX/MathJax
        mathToRender = mathToRender.replace(/\\label\{[^}]+\}/g, '')
      }

      const katex = (window as any).katex
      if (katex) {
        try {
          katex.render(mathToRender, element, {
            displayMode: this.displayMode,
            throwOnError: false,
            trust: true,
            strict: false
          })
          
          // Add label badge if found
          if (labelName && this.displayMode) {
            const badge = document.createElement('div')
            badge.className = 'ol-cm-math-label-badge'
            badge.textContent = `eq: ${labelName}`
            element.appendChild(badge)
          }

          // Cache the result (the actual rendered content, not the wrapper)
          if (element.firstChild) {
            const cacheKey = `${this.math}-${this.displayMode}`
            mathCache.set(cacheKey, {
              svg: element.firstChild.cloneNode(true) as HTMLElement,
              label: labelName
            })
          }

          element.style.height = 'auto'
          const measuredHeight = element.offsetHeight
          this.cachedHeight = measuredHeight > 0 ? measuredHeight : (this.displayMode ? 40 : 20)
          return
        } catch (e) {
          console.error('KaTeX error:', e)
        }
      }

      // Fallback to MathJax
      const MathJax = await loadMathJax()
      if (this.destroyed || !element.isConnected) return

      const math = await MathJax.tex2svgPromise(mathToRender, {
        display: this.displayMode,
      })
      
      if (this.destroyed || !element.isConnected) return
      
      element.replaceChildren(math)

      // Add label badge for MathJax too
      if (labelName && this.displayMode) {
        const badge = document.createElement('div')
        badge.className = 'ol-cm-math-label-badge'
        badge.textContent = `eq: ${labelName}`
        element.appendChild(badge)
      }

      // Cache the MathJax result too
      if (element.firstChild) {
        const cacheKey = `${this.math}-${this.displayMode}`
        mathCache.set(cacheKey, {
          svg: element.firstChild.cloneNode(true) as HTMLElement,
          label: labelName
        })
      }

      element.style.height = 'auto'
      const measuredHeight = element.offsetHeight
      this.cachedHeight = measuredHeight > 0 ? measuredHeight : (this.displayMode ? 40 : 20)
    } catch (err) {
      console.error('Math render error:', err)
      element.textContent = 'Math Error'
    } finally {
      this.rendering = false
    }
  }
}
