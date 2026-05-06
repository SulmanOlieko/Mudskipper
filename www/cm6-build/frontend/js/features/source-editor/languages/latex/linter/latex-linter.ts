import { EditorView } from '@codemirror/view'
import { Diagnostic } from '@codemirror/lint'
import { errorsToDiagnostics } from './errors-to-diagnostics'
import { mergeCompatibleOverlappingDiagnostics } from './merge-overlapping-diagnostics'

let lintWorker: Worker | null = null
const pendingRequests = new Map<number, { 
  resolve: (value: Diagnostic[]) => void, 
  view: EditorView,
  docText: string 
}>()
let currentRequestId = 0

const getWorker = () => {
  if (!lintWorker) {
    lintWorker = new Worker('/latex-linter.worker.js')
    
    lintWorker.addEventListener('message', event => {
      const { errors, requestId } = event.data
      const pending = pendingRequests.get(requestId)
      
      if (pending) {
        const { resolve, view } = pending
        pendingRequests.delete(requestId)
        
        const doc = view.state.doc
        const cursorPosition = view.state.selection?.main?.head || 0
        
        const rawDiagnostics = errorsToDiagnostics(errors, cursorPosition, doc.length)
        const mergedDiagnostics = mergeCompatibleOverlappingDiagnostics(rawDiagnostics)
        
        // Enrich diagnostics with row, column, text for the host application and Ace
        const enrichedDiagnostics = mergedDiagnostics.map(d => {
          let row = 0, column = 0;
          try {
            const line = doc.lineAt(d.from);
            row = line.number - 1;
            column = d.from - line.from;
          } catch (e) {}
          
          return {
            ...d,
            type: d.severity,
            row: row,
            column: column,
            text: typeof d.message === 'string' ? d.message : 'Error'
          };
        });

        if (requestId === currentRequestId) {
          if (typeof window !== 'undefined' && (window as any).updateErrorLog) {
            (window as any).updateErrorLog(enrichedDiagnostics)
          }
        }

        resolve(enrichedDiagnostics as any)
      }
    })

    lintWorker.addEventListener('error', err => {
      console.error('[LatexLinter] Worker error:', err)
      for (const [id, pending] of pendingRequests) {
        pending.resolve([])
      }
      pendingRequests.clear()
    })
  }
  return lintWorker
}

export const latexLinter = async (view: EditorView): Promise<Diagnostic[]> => {
  return new Promise(resolve => {
    const worker = getWorker()
    currentRequestId++
    const requestId = currentRequestId
    
    const docText = view.state.doc.toString()
    pendingRequests.set(requestId, { resolve, view, docText })
    
    worker.postMessage({
      action: 'lint',
      text: docText,
      requestId
    })
    
    if (pendingRequests.size > 20) {
      const oldestId = Array.from(pendingRequests.keys())[0]
      const oldest = pendingRequests.get(oldestId)
      if (oldest) {
        oldest.resolve([])
        pendingRequests.delete(oldestId)
      }
    }
  })
}
