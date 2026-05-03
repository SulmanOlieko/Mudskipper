import { linter, LintSource } from '@codemirror/lint'
import { Extension } from '@codemirror/state'

export const createLinter = (
  source: LintSource,
  config: any = {}
): Extension => {
  return linter(source, config)
}
