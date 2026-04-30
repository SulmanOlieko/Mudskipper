import {
  EditorView,
  rectangularSelection,
  tooltips,
  crosshairCursor,
  dropCursor,
  highlightActiveLineGutter,
} from '@codemirror/view'
import { EditorState, Extension } from '@codemirror/state'
import { foldGutter, indentOnInput, indentUnit } from '@codemirror/language'
import { history } from '@codemirror/commands'
import { lineWrappingIndentation } from './line-wrapping-indentation'
import { theme } from './theme'
import { editable } from './editable'
import { filterCharacters } from './filter-characters'
import { bracketMatching, bracketSelection } from './bracket-matching'
import { verticalOverflow } from './vertical-overflow'
import { lineNumbers } from './line-numbers'
import { highlightActiveLine } from './highlight-active-line'
import { emptyLineFiller } from './empty-line-filler'
import { drawSelection } from './draw-selection'
import { sourceOnly, visual } from './visual/visual'
import { inlineBackground } from './inline-background'
import { keymaps } from './keymaps'
import { effectListeners } from './effect-listeners'
import { highlightSpecialChars } from './highlight-special-chars'
import { geometryChangeEvent } from './geometry-change-event'

export const createExtensions = (options: Record<string, any>): Extension[] => [
  lineNumbers(),
  highlightSpecialChars(options.visual.visual),
  // The built-in extension that manages the history stack,
  // configured to increase the maximum delay between adjacent grouped edits
  history({ newGroupDelay: 250 }),
  // The built-in extension that displays buttons for folding code in a gutter element,
  // configured with custom openText and closeText symbols.
  foldGutter({
    openText: '▾',
    closedText: '▸',
  }),
  drawSelection(),
  // A built-in facet that is set to true to allow multiple selections.
  EditorState.allowMultipleSelections.of(true),
  // A built-in extension that enables soft line wrapping.
  EditorView.lineWrapping,
  sourceOnly(
    options.visual.visual,
    EditorView.contentAttributes.of({ 'aria-label': 'Source Editor editing' })
  ),
  // A built-in extension that re-indents input if the language defines an indentOnInput field in its language data.
  indentOnInput(),
  lineWrappingIndentation(options.visual.visual),
  bracketMatching(),
  bracketSelection(),
  // A built-in extension that enables rectangular selections, created by dragging a new selection while holding down Alt.
  rectangularSelection(),
  // A built-in extension that turns the pointer into a crosshair while Alt is pressed.
  crosshairCursor(),
  // A built-in extension that shows where dragged content will be dropped.
  dropCursor(),
  // A built-in extension that is used for configuring tooltip behaviour,
  // configured so that the tooltip parent is the document body,
  // to avoid cutting off tooltips which overflow the editor.
  tooltips({
    parent: document.body,
    tooltipSpace(view) {
      const { top, bottom } = view.scrollDOM.getBoundingClientRect()

      return {
        top,
        left: 0,
        bottom,
        right: window.innerWidth,
      }
    },
  }),
  keymaps,
  filterCharacters(),

  indentUnit.of('    '), // 4 spaces
  theme(options.theme),
  editable(),
  // NOTE: `emptyLineFiller` needs to be before `trackChanges`,
  // so the decorations are added in the correct order.
  emptyLineFiller(),
  visual(options.visual),
  verticalOverflow(),
  highlightActiveLine(options.visual.visual),
  // The built-in extension that highlights the active line in the gutter.
  highlightActiveLineGutter(),
  inlineBackground(options.visual.visual),
  // Send exceptions to Sentry
  EditorView.exceptionSink.of(options.handleException),
  effectListeners(),
  geometryChangeEvent(),
]
