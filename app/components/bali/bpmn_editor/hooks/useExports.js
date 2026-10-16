import { useCallback, useMemo } from 'react'
import { toBpmnXml } from '../model/bpmnXml.js'
import { resolveColors, renderSvg, download, downloadPng, printSvg, fileName } from '../export/exporters.js'

// The top bar's outputs: the .bpmn file, and the diagram as SVG, PNG and
// print — drawn from the document, not from the canvas on screen.
export default function useExports ({ doc, name, watermark, tags, page, wrapperRef }) {
  const exportSvg = useCallback(() => {
    const { paint, colors } = resolveColors(wrapperRef.current)
    return renderSvg({ doc, paint, colors, title: name || null, subtitle: doc.status_label || null, watermark: watermark || null, notes: doc.annotations || [], tags, page })
  }, [doc, name, watermark, tags, page, wrapperRef])
  return useMemo(() => ({
    bpmn: () => download(fileName(name, 'bpmn'), toBpmnXml(doc, { name }), 'application/xml'),
    svg: () => download(fileName(name, 'svg'), exportSvg(), 'image/svg+xml'),
    png: () => downloadPng(fileName(name, 'png'), exportSvg()),
    print: () => printSvg(exportSvg(), name, page)
  }), [doc, name, exportSvg, page])
}
