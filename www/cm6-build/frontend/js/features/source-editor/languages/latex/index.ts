import { latexIndentService } from './latex-indent-service'
import { linting } from './linting'
import { LanguageSupport } from '@codemirror/language'
import { documentCommands } from './document-commands'
import { documentOutline } from './document-outline'
import { LaTeXLanguage } from './latex-language'
import { documentEnvironments } from './document-environments'
import {
  figureModal,
  figureModalPasteHandler,
} from '../../extensions/figure-modal'

export const latex = () => {
  return new LanguageSupport(LaTeXLanguage, [
    documentOutline,
    documentCommands,
    documentEnvironments,
    latexIndentService(),
    figureModal(),
    figureModalPasteHandler(),
    linting(),
  ])
}
