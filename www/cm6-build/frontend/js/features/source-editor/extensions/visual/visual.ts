import {
  Compartment,
  EditorState,
  Extension,
  StateEffect,
  StateField,
  TransactionSpec,
} from '@codemirror/state'
import { visualHighlightStyle, visualTheme } from './visual-theme'
import { atomicDecorations } from './atomic-decorations'
import { markDecorations } from './mark-decorations'
import { EditorView, ViewPlugin } from '@codemirror/view'
import { visualKeymap } from './visual-keymap'
import { mousedown, mouseDownEffect } from './selection'
import { forceParsing, syntaxTree } from '@codemirror/language'
import { hasLanguageLoadedEffect } from '../language'
import { listItemMarker } from './list-item-marker'
import { pasteHtml } from './paste-html'
import { tableGeneratorTheme } from './table-generator'
import { debugConsole } from '@/utils/debugging'
import { PreviewPath } from '../../../../../../types/preview-path'

type Options = {
  visual: boolean
  previewByPath: (path: string) => PreviewPath | null
}

const visualConf = new Compartment()

export const toggleVisualEffect = StateEffect.define<boolean>()

const visualState = StateField.define<boolean>({
  create() {
    return false
  },
  update(value, tr) {
    for (const effect of tr.effects) {
      if (effect.is(toggleVisualEffect)) {
        return effect.value
      }
    }
    return value
  },
})

const configureVisualExtensions = (options: Options) =>
  options.visual ? extension(options) : []

export const visual = (options: Options): Extension => {
  return [
    visualState.init(() => options.visual),
    visualConf.of(configureVisualExtensions(options)),
  ]
}

export const isVisual = (view: EditorView) => {
  return view.state.field(visualState, false) || false
}

export const setVisual = (options: Options): TransactionSpec => {
  return {
    effects: [
      toggleVisualEffect.of(options.visual),
      visualConf.reconfigure(configureVisualExtensions(options)),
    ],
  }
}

export const sourceOnly = (visual: boolean, extension: Extension) => {
  const conf = new Compartment()
  const configure = (visual: boolean) => (visual ? [] : extension)
  return [
    conf.of(configure(visual)),

    // Respond to switching editor modes
    EditorState.transactionExtender.of(tr => {
      for (const effect of tr.effects) {
        if (effect.is(toggleVisualEffect)) {
          return {
            effects: conf.reconfigure(configure(effect.value)),
          }
        }
      }
      return null
    }),
  ]
}

const parsedAttributesConf = new Compartment()

/**
 * Parse the document incrementally using requestAnimationFrame so each chunk
 * respects the 16ms frame budget and the main thread stays responsive.
 */
function parseChunked(
  view: EditorView,
  totalLength: number,
  onComplete: () => void
): void {
  const FRAME_BUDGET_MS = 14 // leave 2ms headroom per frame

  function tick() {
    // forceParsing expects a timeout duration in ms, not a deadline timestamp!
    const done = forceParsing(view, totalLength, FRAME_BUDGET_MS)
    if (done) {
      onComplete()
    } else {
      requestAnimationFrame(tick)
    }
  }

  requestAnimationFrame(tick)
}

/**
 * A view plugin which marks the editor as visually "parsed" (adds the
 * ol-cm-parsed CSS class) once the initial decorations have been applied.
 * Editing is always enabled — the editable() extension owns that lifecycle.
 */
export const showContentWhenParsed = [
  // Only manage the CSS class — no longer blocks editability here.
  parsedAttributesConf.of([]),
  ViewPlugin.define(view => {
    const markParsed = () => {
      view.dispatch({
        effects: parsedAttributesConf.reconfigure([
          EditorView.editorAttributes.of({
            class: 'ol-cm-parsed',
          }),
        ]),
      })
      view.focus()
    }

    // If the document is already fully parsed (e.g. empty or tiny file),
    // mark immediately in the next microtask.
    if (syntaxTree(view.state).length === view.state.doc.length) {
      window.setTimeout(markParsed)
      return {}
    }

    // Fallback: always mark parsed after 5 s even if the parser is stuck.
    const fallbackTimer = window.setTimeout(markParsed, 5000)

    let languageLoaded = false

    return {
      update(update) {
        // Wait for the language to load before triggering the parser.
        if (!languageLoaded && hasLanguageLoadedEffect(update)) {
          languageLoaded = true
          // Defer so we are outside the current dispatch cycle, then parse
          // chunk-by-chunk to avoid blocking the main thread.
          window.setTimeout(() => {
            parseChunked(view, view.state.doc.length, () => {
              window.clearTimeout(fallbackTimer)
              // Give decorations one more frame to build before marking.
              window.setTimeout(markParsed)
            })
          })
        }
      },
    }
  }),
]

/**
 * A transaction extender which scrolls mouse clicks into view, in case decorations have moved the cursor out of view.
 */
const scrollJumpAdjuster = EditorState.transactionExtender.of(tr => {
  // Attach a "scrollIntoView" effect on all mouse selections to adjust for
  // any jumps that may occur when hiding/showing decorations.
  if (!tr.scrollIntoView) {
    for (const effect of tr.effects) {
      if (effect.is(mouseDownEffect) && effect.value === false) {
        return {
          effects: EditorView.scrollIntoView(tr.newSelection.main.head),
        }
      }
    }
  }

  return {}
})

const extension = (options: Options) => [
  visualTheme,
  visualHighlightStyle,
  mousedown,
  listItemMarker,
  atomicDecorations(options),
  markDecorations, // NOTE: must be after atomicDecorations, so that mark decorations wrap inline widgets
  visualKeymap,
  scrollJumpAdjuster,
  showContentWhenParsed,
  pasteHtml,
  tableGeneratorTheme,
  EditorView.contentAttributes.of({ 'aria-label': 'Visual Editor editing' }),
]
