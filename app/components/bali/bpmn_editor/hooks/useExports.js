import { useCallback, useMemo, useRef } from 'react'
import { toBpmnXml } from '../model/bpmnXml.js'
import { resolveColors, renderSvg, download, downloadPng, printSvg, fileName } from '../export/exporters.js'

// The top bar's outputs: the .bpmn file, and the diagram as SVG, PNG and
// print — drawn from the document, not from the canvas on screen. An output
// that fails calls `onError` (the editor's notice); the PNG's failure is a
// rejected promise nothing else would catch.
export default function useExports ({ doc, name, watermark, tags, page, wrapperRef, badges = true, onError = null }) {
  const onErrorRef = useRef(onError)
  onErrorRef.current = onError
  const exportSvg = useCallback(() => {
    const { paint, colors } = resolveColors(wrapperRef.current)
    return renderSvg({ doc, paint, colors, title: name || null, subtitle: doc.status_label || null, watermark: watermark || null, notes: doc.annotations || [], tags, page, badges })
  }, [doc, name, watermark, tags, page, wrapperRef, badges])
  return useMemo(() => {
    const fail = (error) => {
      console.error(error)
      if (onErrorRef.current) onErrorRef.current(error)
    }
    const guarded = (run) => () => {
      try {
        return Promise.resolve(run()).catch(fail)
      } catch (error) {
        fail(error)
        return Promise.resolve()
      }
    }
    return {
      bpmn: guarded(() => download(fileName(name, 'bpmn'), toBpmnXml(doc, { name }), 'application/xml')),
      svg: guarded(() => download(fileName(name, 'svg'), exportSvg(), 'image/svg+xml')),
      png: guarded(() => downloadPng(fileName(name, 'png'), exportSvg())),
      print: guarded(() => printSvg(exportSvg(), name, page))
    }
  }, [doc, name, exportSvg, page])
}
