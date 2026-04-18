import { ElementType } from 'react'
const importOverleafModules = () => [];

const componentModule = importOverleafModules('fullProjectSearchPanel')[0] as
  | {
      import: { default: ElementType }
      path: string
    }
  | undefined

export const FullProjectSearchPanel = () => {
  if (!componentModule) {
    return null
  }
  const FullProjectSearch = componentModule.import.default
  return <FullProjectSearch />
}

export const hasFullProjectSearch = Boolean(componentModule)
