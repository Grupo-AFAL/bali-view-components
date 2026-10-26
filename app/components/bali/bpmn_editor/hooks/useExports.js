import { useCallback, useMemo, useRef } from 'react'
import { toBpmnXml } from '../model/bpmnXml.js'
import { summaryText } from '../model/diff.js'
import { changeRows } from '../model/compareChanges.js'
import { resolveColors, renderSvg, download, downloadPng, printSvg, fileName, svgSize, pngDataUrl, pngScale } from '../export/exporters.js'

// The top bar's outputs: the .bpmn file, and the diagram as SVG, PNG and
// print — drawn from the document, not from the canvas on screen. An output
// that fails calls `onError` (the editor's notice); the PNG's failure is a
// rejected promise nothing else would catch.
// `forHost` answers `bali-bpmn:export` (model/exportRequest.js): the same
// drawing, returned instead of downloaded.
export default function useExports ({ doc, name, watermark, tags, page, wrapperRef, badges = true, onError = null, t = null }) {
  const onErrorRef = useRef(onError)
  onErrorRef.current = onError
  const exportSvg = useCallback(() => {
    const { paint, colors } = resolveColors(wrapperRef.current)
    return renderSvg({ doc, paint, colors, title: name || null, subtitle: doc.status_label || null, watermark: watermark || null, notes: doc.annotations || [], tags, page, badges })
  }, [doc, name, watermark, tags, page, wrapperRef, badges])

  // `frame: false` is the drawing alone, at its own size: no title, status
  // label, watermark or sheet — the host lays it in its own template.
  const forHost = useCallback(async ({ format, frame, fontFamily }, comparison = null) => {
    const { paint, colors } = resolveColors(wrapperRef.current)
    const drawing = async (props, subtitle) => {
      const svg = renderSvg({
        paint,
        colors,
        tags,
        badges,
        fontFamily: fontFamily || undefined,
        ...props,
        title: frame ? name || null : null,
        subtitle: frame ? subtitle || null : null,
        watermark: frame ? watermark || null : null,
        page: frame ? page : null
      })
      const size = svgSize(svg)
      if (format === 'png') return { png: await pngDataUrl(svg), scale: pngScale(size), ...size }
      return { svg, ...size }
    }
    const result = { format, frame, ...await drawing({ doc, notes: doc.annotations || [] }, doc.status_label) }
    if (!comparison) return result
    const { base, diff, label, index, mode } = comparison
    return {
      ...result,
      comparison: {
        label: label || null,
        index,
        mode,
        before: await drawing({ doc: base, diff: diff.base }, `${t('compare_base')} · ${label || ''}`),
        after: await drawing({ doc, diff: diff.current }, t('compare_current')),
        summary: { ...diff.summary, text: summaryText(t, diff.summary) },
        changes: changeRows(base, doc, diff, t)
      }
    }
  }, [doc, name, watermark, tags, page, wrapperRef, badges, t])

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
      print: guarded(() => printSvg(exportSvg(), name, page)),
      forHost
    }
  }, [doc, name, exportSvg, page, forHost])
}
