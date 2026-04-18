import React, { ElementType, FC } from 'react'
const importOverleafModules = () => [];

const symbolPaletteComponents = importOverleafModules(
  'sourceEditorSymbolPalette'
) as { import: { default: ElementType }; path: string }[]

const SymbolPalettePane: FC = () => {
  return (
    <div className="ide-react-symbol-palette">
      {symbolPaletteComponents.map(
        ({ import: { default: Component }, path }) => (
          <Component key={path} />
        )
      )}
    </div>
  )
}

export default SymbolPalettePane
