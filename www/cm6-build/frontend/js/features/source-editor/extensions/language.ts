import {
  Compartment,
  StateEffect,
  StateField,
} from '@codemirror/state'
import { languages } from '../languages'
import { ViewPlugin } from '@codemirror/view'
import { indentUnit, LanguageDescription } from '@codemirror/language'
import { updateHasEffect } from '../utils/effects'

export const languageLoadedEffect = StateEffect.define()
export const hasLanguageLoadedEffect = updateHasEffect(languageLoadedEffect)

const languageConf = new Compartment()
const languageCompartment = new Compartment()

/**
 * The parser and support extensions for each supported language,
 * which are loaded dynamically as needed.
 */
export const language = (docName: string) =>
  languageCompartment.of(buildExtension(docName))

const buildExtension = (docName: string) => {
  const languageDescription = LanguageDescription.matchFilename(
    languages,
    docName
  )

  if (!languageDescription) {
    return []
  }

  return [
    /**
     * Default to four-space indentation and set the configuration in advance,
     * to prevent a shift in line indentation markers when the LaTeX language loads.
     */
    languageConf.of(indentUnit.of('    ')),
    /**
     * A view plugin which loads the appropriate language for the current file extension,
     * then dispatches an effect so other extensions can update accordingly.
     */
    ViewPlugin.define(view => {
      // load the language asynchronously
      languageDescription.load().then(support => {
        view.dispatch({
          effects: [
            languageConf.reconfigure(support),
            languageLoadedEffect.of(null),
          ],
        })
      })

      return {}
    }),
  ]
}
