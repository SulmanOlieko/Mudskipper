import { createRoot, Root } from 'react-dom/client'
import React from 'react'
import { EditorView, WidgetType } from '@codemirror/view'
import { SyntaxNode } from '@lezer/common'
import { Tabular } from '../../../components/table-generator/tabular'
import { ParsedTableData } from '../../../components/table-generator/utils'

import { I18nextProvider } from 'react-i18next'
import i18n from '@/infrastructure/i18n'

export class TabularWidget extends WidgetType {
  static roots: WeakMap<HTMLElement, Root> = new WeakMap()

  constructor(
    private parsedTableData: ParsedTableData,
    private tabularNode: SyntaxNode,
    private content: string,
    private tableNode: SyntaxNode | null,
    private isDirectChildOfTableEnvironment: boolean
  ) {
    super()
  }

  renderInDOMContainer(children: React.ReactNode, element: HTMLElement) {
    const root = TabularWidget.roots.get(element) || createRoot(element)
    if (!TabularWidget.roots.get(element)) {
      TabularWidget.roots.set(element, root)
    }
    root.render(<I18nextProvider i18n={i18n}>{children}</I18nextProvider>)
  }

  toDOM(view: EditorView) {
    const element = document.createElement('div')
    element.classList.add('ol-cm-tabular')
    if (this.tableNode) {
      element.classList.add('ol-cm-environment-table')
    }
    this.renderInDOMContainer(
      <Tabular
        view={view}
        tabularNode={this.tabularNode}
        parsedTableData={this.parsedTableData}
        tableNode={this.tableNode}
        directTableChild={this.isDirectChildOfTableEnvironment}
      />,
      element
    )
    return element
  }

  eq(widget: TabularWidget): boolean {
    return (
      this.tabularNode.from === widget.tabularNode.from &&
      this.tableNode?.from === widget.tableNode?.from &&
      this.tableNode?.to === widget.tableNode?.to &&
      this.content === widget.content &&
      this.isDirectChildOfTableEnvironment ===
        widget.isDirectChildOfTableEnvironment
    )
  }

  updateDOM(element: HTMLElement, view: EditorView): boolean {
    this.renderInDOMContainer(
      <Tabular
        view={view}
        tabularNode={this.tabularNode}
        parsedTableData={this.parsedTableData}
        tableNode={this.tableNode}
        directTableChild={this.isDirectChildOfTableEnvironment}
      />,
      element
    )
    return true
  }

  coordsAt(element: HTMLElement) {
    return element.getBoundingClientRect()
  }

  get estimatedHeight() {
    return this.parsedTableData.table.rows.length * 50
  }

  destroy(element: HTMLElement) {
    const root = TabularWidget.roots.get(element)
    if (root) {
      TabularWidget.roots.delete(element)
      root.unmount()
    }
  }
}
