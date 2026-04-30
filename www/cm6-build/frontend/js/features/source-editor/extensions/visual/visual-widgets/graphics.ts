import { EditorView, WidgetType } from '@codemirror/view'
import { placeSelectionInsideBlock } from '../selection'
import { isEqual } from 'lodash'
import { FigureData } from '../../figure-modal'
import { PreviewPath } from '../../../../../../../types/preview-path'

export class GraphicsWidget extends WidgetType {
  destroyed = false
  height = 300 // for estimatedHeight, updated when the image is loaded

  constructor(
    public filePath: string,
    public previewByPath: (path: string) => PreviewPath | null,
    public centered: boolean,
    public figureData: FigureData | null
  ) {
    super()
  }

  toDOM(view: EditorView): HTMLElement {
    this.destroyed = false

    const element = document.createElement('div')
    element.classList.add('ol-cm-environment-figure')
    element.classList.add('ol-cm-environment-line')
    element.classList.toggle('ol-cm-environment-centered', this.centered)

    this.renderGraphic(element, view)

    element.addEventListener('mouseup', event => {
      event.preventDefault()
      view.dispatch(placeSelectionInsideBlock(view, event as MouseEvent))
    })

    return element
  }

  eq(widget: GraphicsWidget) {
    return (
      widget.filePath === this.filePath &&
      widget.centered === this.centered &&
      isEqual(this.figureData, widget.figureData)
    )
  }

  updateDOM(element: HTMLElement, view: EditorView) {
    this.destroyed = false
    element.classList.toggle('ol-cm-environment-centered', this.centered)
    
    const inner = element.querySelector('.ol-cm-graphics, .ol-cm-graphics-loading-placeholder')
    if (inner && (inner as HTMLElement).dataset?.filepath === this.filePath) {
      return true
    }

    this.renderGraphic(element, view)
    view.requestMeasure()
    return true
  }

  ignoreEvent(event: Event) {
    return (
      event.type !== 'mouseup' &&
      !(
        event.target instanceof HTMLElement &&
        event.target.closest('.ol-cm-graphics-edit-button')
      )
    )
  }

  destroy() {
    this.destroyed = true
  }

  coordsAt(element: HTMLElement) {
    return element.getBoundingClientRect()
  }

  get estimatedHeight(): number {
    return this.height
  }

  renderGraphic(element: HTMLElement, view: EditorView) {
    element.textContent = ''
    const wrapper = document.createElement('div')
    wrapper.dataset.filepath = this.filePath
    element.appendChild(wrapper)

    const preview = this.previewByPath(this.filePath)
    
    if (!preview) {
      this.showError(wrapper, `Path not found: ${this.filePath}`)
      return
    }

    const { url, extension } = preview
    console.log(`Figure rendering for "${this.filePath}" using URL:`, url)

    if (extension === 'svg') {
      this.renderSvg(view, wrapper, url)
    } else if (extension === 'pdf') {
      this.renderNativePDF(view, wrapper, url)
    } else {
      this.renderDefaultImage(view, wrapper, url)
    }
  }

  private renderNativePDF(view: EditorView, wrapper: HTMLElement, url: string) {
    const image = document.createElement('img')
    image.classList.add('ol-cm-graphics')
    image.dataset.filepath = this.filePath
    const width = this.getFigureWidth()
    image.style.width = width
    image.style.maxWidth = width
    image.style.display = 'block'

    image.addEventListener('load', () => {
      wrapper.textContent = ''
      wrapper.appendChild(image)
      wrapper.classList.remove('ol-cm-graphics-loading-placeholder')
      this.height = image.height > 0 ? image.height : 300
      view.requestMeasure()
    })

    image.addEventListener('error', () => {
      console.warn('Native PDF render failed, falling back to PDF.js')
      this.renderPDF(view, wrapper, url).catch(err => {
        console.error('All PDF methods failed:', err)
        this.showError(wrapper, `PDF Error: ${this.filePath}`)
      })
    })

    image.src = url
  }

  private renderDefaultImage(view: EditorView, wrapper: HTMLElement, url: string) {
    const image = document.createElement('img')
    image.classList.add('ol-cm-graphics')
    image.dataset.filepath = this.filePath
    const width = this.getFigureWidth()
    image.style.width = width
    image.style.maxWidth = width
    image.style.display = 'block'

    image.addEventListener('load', () => {
      wrapper.textContent = ''
      wrapper.appendChild(image)
      wrapper.classList.remove('ol-cm-graphics-loading-placeholder')
      this.height = image.height > 0 ? image.height : 300
      view.requestMeasure()
    })

    image.addEventListener('error', () => {
      this.showError(wrapper, `Load Failed: ${this.filePath}`)
    })

    image.src = url
  }

  private renderSvg(view: EditorView, wrapper: HTMLElement, url: string) {
    const image = document.createElement('img')
    image.classList.add('ol-cm-graphics')
    image.dataset.filepath = this.filePath
    const width = this.getFigureWidth()
    image.style.width = width
    image.style.maxWidth = width

    fetch(url)
      .then(response => {
        if (!response.ok) throw new Error(`Status: ${response.status}`)
        return response.text()
      })
      .then(svgText => {
        if (this.destroyed) return
        const blob = new Blob([svgText], { type: 'image/svg+xml' })
        const objectUrl = URL.createObjectURL(blob)

        const showError = () => {
          URL.revokeObjectURL(objectUrl)
          this.showError(wrapper, `SVG Failed: ${this.filePath}`)
        }

        image.addEventListener('load', () => {
          URL.revokeObjectURL(objectUrl)
          wrapper.textContent = ''
          wrapper.appendChild(image)
          wrapper.classList.remove('ol-cm-graphics-loading-placeholder')
          this.height = image.height > 0 ? image.height : 300
          view.requestMeasure()
        }, { once: true })

        image.addEventListener('error', showError, { once: true })
        image.src = objectUrl
      })
      .catch(() => {
        this.showError(wrapper, `SVG Error: ${this.filePath}`)
      })
  }

  private showError(wrapper: HTMLElement, message: string) {
    wrapper.classList.add('ol-cm-graphics-loading-placeholder')
    wrapper.innerHTML = `<strong>${message}</strong>`
  }

  getFigureWidth() {
    if (this.figureData?.width) {
      return `min(100%, ${this.figureData.width * 100}%)`
    }
    return ''
  }

  async renderPDF(view: EditorView, wrapper: HTMLElement, url: string) {
    const { loadPdfDocumentFromUrl } = await import('@/features/pdf-preview/util/pdf-js')
    if (this.destroyed) return
    const pdf = await loadPdfDocumentFromUrl(url).promise
    const page = await pdf.getPage(1)
    if (this.destroyed) return

    const canvas = document.createElement('canvas')
    canvas.classList.add('ol-cm-graphics')
    const viewport = page.getViewport({ scale: 2 })
    canvas.width = viewport.width
    canvas.height = viewport.height
    
    const width = this.getFigureWidth()
    canvas.style.width = width
    canvas.style.maxWidth = width
    
    await page.render({
      canvasContext: canvas.getContext('2d')!,
      viewport,
    }).promise

    if (this.destroyed) return
    wrapper.textContent = ''
    wrapper.appendChild(canvas)
    this.height = (viewport.height * (parseInt(width) || 800)) / viewport.width || 300
    view.requestMeasure()
  }
}
