// `bali-bpmn:export` { request_id, format, frame, font_family }: the app asks
// for the drawing (hooks/useExports.js forHost) and hears it back as
// `bali-bpmn:exported`, or `bali-bpmn:export-failed` { request_id, message }
// — never a download. `request_id` is the app's own, returned as sent.
export const EXPORT_FORMATS = ['svg', 'png']

// The request as the exporter takes it, or { requestId, error } for one that
// asks for what there is not.
export function exportRequest (detail) {
  const d = detail && typeof detail === 'object' ? detail : {}
  const requestId = d.request_id === undefined ? null : d.request_id
  const format = d.format == null ? 'svg' : d.format
  if (!EXPORT_FORMATS.includes(format)) return { requestId, error: `unknown export format ${JSON.stringify(format)}; expected one of ${EXPORT_FORMATS.join(', ')}` }
  if (d.frame != null && typeof d.frame !== 'boolean') return { requestId, error: `frame must be true or false, got ${JSON.stringify(d.frame)}` }
  const fontFamily = d.font_family == null ? null : d.font_family
  if (fontFamily !== null && (typeof fontFamily !== 'string' || !fontFamily.trim())) return { requestId, error: `font_family must be a CSS font-family list, got ${JSON.stringify(fontFamily)}` }
  return { requestId, format, frame: d.frame !== false, fontFamily: fontFamily && fontFamily.trim() }
}

// Runs `run (request)` and announces its outcome through `emit (name, detail)`.
export async function answerExport (detail, run, emit) {
  const request = exportRequest(detail)
  if (request.error) {
    emit('export-failed', { request_id: request.requestId, message: request.error })
    return
  }
  try {
    emit('exported', { request_id: request.requestId, ...await run(request) })
  } catch (error) {
    emit('export-failed', { request_id: request.requestId, message: (error && error.message) || String(error) })
  }
}
