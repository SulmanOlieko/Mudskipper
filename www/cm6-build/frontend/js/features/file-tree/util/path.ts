import { Folder } from '../../../../../types/folder'
import { FileTreeEntity } from '../../../../../types/file-tree-entity'
import { Doc } from '../../../../../types/doc'
import { FileRef } from '../../../../../types/file-ref'
import { PreviewPath } from '../../../../../types/preview-path'

type DocFindResult = {
  entity: Doc
  type: 'doc'
}

type FolderFindResult = {
  entity: Folder
  type: 'folder'
}

type FileRefFindResult = {
  entity: FileRef
  type: 'fileRef'
}

export type FindResult = DocFindResult | FolderFindResult | FileRefFindResult

function pathComponentsInFolder(
  folder: Folder,
  id: string,
  ancestors: FileTreeEntity[] = []
): FileTreeEntity[] | null {
  const docOrFileRef =
    (folder.docs || []).find(doc => doc._id === id) ||
    (folder.fileRefs || []).find(fileRef => fileRef._id === id)
  if (docOrFileRef) {
    return ancestors.concat([docOrFileRef])
  }

  for (const subfolder of folder.folders || []) {
    if (subfolder._id === id) {
      return ancestors.concat([subfolder])
    } else {
      const path = pathComponentsInFolder(
        subfolder,
        id,
        ancestors.concat([subfolder])
      )
      if (path !== null) {
        return path
      }
    }
  }

  return null
}

export function pathInFolder(folder: Folder, id: string): string | null {
  return (
    pathComponentsInFolder(folder, id)
      ?.map(entity => entity.name)
      .join('/') || null
  )
}

export function findEntityByPath(
  folder: Folder,
  path: string
): FindResult | null {
  if (!path || path === '' || path === '/') {
    return { entity: folder, type: 'folder' }
  }

  const parts = path.split('/').filter(Boolean)
  if (parts.length === 0) return { entity: folder, type: 'folder' }

  const name = parts.shift()
  const rest = parts.join('/')

  if (name === '.') {
    return findEntityByPath(folder, rest)
  }

  const doc = (folder.docs || []).find(doc => doc.name === name)
  if (doc) {
    return { entity: doc, type: 'doc' }
  }

  const fileRef = (folder.fileRefs || []).find(fileRef => fileRef.name === name)
  if (fileRef) {
    return { entity: fileRef, type: 'fileRef' }
  }

  for (const subfolder of folder.folders || []) {
    if (subfolder.name === name) {
      if (rest === '') {
        return { entity: subfolder, type: 'folder' }
      } else {
        return findEntityByPath(subfolder, rest)
      }
    }
  }

  return null
}

/**
 * Mudskipper-specific: Dynamic search for a file anywhere in the project tree.
 */
export function findEntityAnywhere(
  folder: Folder,
  filename: string,
  currentPath: string = ''
): { entity: FileRef | Doc; path: string } | null {
  const ignoredFolders = ['history', 'chat_files', 'comments', 'compiled_cache', '.git']
  if (ignoredFolders.includes(folder.name)) return null

  // Check files and docs in current folder
  const file = (folder.fileRefs || []).find(f => f.name === filename)
  if (file) {
    console.log(`[AnywhereSearch] FOUND "${filename}" at "${currentPath}${file.name}"`)
    return { entity: file, path: currentPath + file.name }
  }
  
  const doc = (folder.docs || []).find(d => d.name === filename)
  if (doc) {
    console.log(`[AnywhereSearch] FOUND doc "${filename}" at "${currentPath}${doc.name}"`)
    return { entity: doc, path: currentPath + doc.name }
  }

  // Recurse into subfolders
  for (const sub of folder.folders || []) {
    const result = findEntityAnywhere(sub, filename, currentPath + sub.name + '/')
    if (result) return result
  }

  return null
}

export function previewByPath(
  folder: Folder,
  projectId: string,
  path: string
): PreviewPath | null {
  if (!folder) return null

  // Strategy 1: Try exact path match
  let result = findEntityByPath(folder, path)
  let foundPath = path
  let method = 'direct'

  // Strategy 2: If no direct match, search anywhere (Dynamic Discovery)
  if (!result) {
    const filename = path.split('/').pop() || path
    const searchResult = findEntityAnywhere(folder, filename)
    if (searchResult) {
      result = { entity: searchResult.entity, type: 'fileRef' }
      foundPath = searchResult.path
      method = 'discovery'
    }
  }

  if (result?.entity) {
    const name = result.entity.name
    const extension = name.slice(name.lastIndexOf('.') + 1).toLowerCase()
    
    const activePath = (window as any).activeProjectPath
    const url = activePath 
      ? (activePath.endsWith('/') ? activePath : activePath + '/') + foundPath
      : `/project/${foundPath}`

    console.log(`[PathResolver] SUCCESS: "${path}" resolved via ${method} to "${foundPath}"`)
    return { url, extension }
  }

  return null
}

export function dirname(fileTreeData: Folder, id: string) {
  const path = pathInFolder(fileTreeData, id)
  return path?.split('/').slice(0, -1).join('/') || null
}
