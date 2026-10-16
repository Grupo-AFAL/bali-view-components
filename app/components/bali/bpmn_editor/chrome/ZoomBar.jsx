import { Panel, useReactFlow, useViewport } from '@xyflow/react'
import Icon from './icons.jsx'
import { fitDiagram } from '../canvas/fit.js'

// Zoom with a visible percentage, "Center the flow", and — when editing —
// "Select all" with the selection counter (the tablet path to multi-select).
export default function ZoomBar ({ t, onSelectAll, selectedCount = 0, boxSelect, onBoxSelect, fit = { padding: 0.12 } }) {
  const flow = useReactFlow()
  const { zoomIn, zoomOut } = flow
  const { zoom } = useViewport()
  const button = 'btn btn-ghost btn-xs btn-square'
  return (
    <Panel position='bottom-left' className='bpmn-chrome flex items-center gap-2'>
      <div className='flex items-center rounded-lg border border-base-300 bg-base-100 shadow-sm' role='group' aria-label={t('zoom_in')}>
        <button type='button' className={button} onClick={() => zoomOut({ duration: 150 })} aria-label={t('zoom_out')} title={t('zoom_out')}>
          <Icon name='minus' size={14} />
        </button>
        <span className='w-12 text-center font-mono text-xs tabular-nums' aria-live='polite'>{Math.round(zoom * 100)}%</span>
        <button type='button' className={button} onClick={() => zoomIn({ duration: 150 })} aria-label={t('zoom_in')} title={t('zoom_in')}>
          <Icon name='plus' size={14} />
        </button>
        <button type='button' className={button} onClick={() => fitDiagram(flow, fit, 200)} aria-label={t('center')} title={t('center')}>
          <Icon name='crosshair' size={14} />
        </button>
      </div>
      {onSelectAll && (
        <button type='button' className='btn btn-xs border-base-300 bg-base-100 shadow-sm' onClick={onSelectAll} title='Ctrl+A'>
          <Icon name='selectAll' size={14} />{t('select_all')}
        </button>
      )}
      {onBoxSelect && (
        <button type='button' className={`btn btn-xs border-base-300 bg-base-100 shadow-sm ${boxSelect ? 'btn-active text-primary' : ''}`} onClick={onBoxSelect} title={t('select_mode_hint')} aria-pressed={String(Boolean(boxSelect))}>
          <Icon name='selectAll' size={14} />{t('select_mode')}
        </button>
      )}
      {selectedCount > 0 && <span className='text-xs text-base-content/70'>{t('selected_count', { count: selectedCount })}</span>}
    </Panel>
  )
}
