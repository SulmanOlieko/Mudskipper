import '@/utils/abortsignal-polyfill'
import { getDocument, GlobalWorkerOptions, version } from 'pdfjs-dist'
const PDFJS = { getDocument, GlobalWorkerOptions, version }
import type { DocumentInitParameters } from 'pdfjs-dist/types/src/display/api'

export { PDFJS }

// Use a CDN worker to avoid build-time 'import.meta.url' issues
PDFJS.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${PDFJS.version}/build/pdf.worker.min.mjs`

export const imageResourcesPath = '/images/pdfjs-dist/'
const cMapUrl = '/js/pdfjs-dist/cmaps/'
const wasmUrl = '/js/pdfjs-dist/wasm/'
const iccUrl = '/js/pdfjs-dist/iccs/'
const standardFontDataUrl = '/fonts/pdfjs-dist/'

const params = new URLSearchParams(window.location.search)
const disableFontFace = params.get('disable-font-face') === 'true'
const disableStream = process.env.NODE_ENV !== 'test'

export const loadPdfDocumentFromUrl = (
  url: string,
  options: Partial<DocumentInitParameters> = {}
) =>
  PDFJS.getDocument({
    url,
    cMapUrl,
    wasmUrl,
    iccUrl,
    standardFontDataUrl,
    disableFontFace,
    disableAutoFetch: true, // only fetch the data needed for the displayed pages
    disableStream,
    isEvalSupported: false,
    enableXfa: false, // default is false (2021-10-12), but set explicitly to be sure
    ...options,
  })
