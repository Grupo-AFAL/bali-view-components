import { Panel } from '@xyflow/react'
import Icon from './icons.jsx'

function Tool ({ icon, label, title, onClick, active, disabled, testId }) {
  return (
    <button
      type='button'
      className={`btn btn-ghost btn-sm gap-1 font-normal ${active ? 'btn-active text-primary' : ''}`}
      onClick={onClick} disabled={disabled} title={title || label} aria-pressed={active == null ? undefined : String(Boolean(active))}
      data-testid={testId}
    >
      <Icon name={icon} size={15} /><span className='bpmn-tool-label'>{label}</span>
    </button>
  )
}

// Floating bar over the canvas: lanes, orientation, layout, connect, import
// on the left; participants, navigate and full screen on the right.
export function CanvasToolbar ({ t, editable, orientation, onAddLane, onToggleOrientation, onAutoLayout, connecting, onConnect, onImport }) {
  if (!editable) return null
  const next = orientation === 'horizontal' ? 'vertical' : 'horizontal'
  return (
    // Wraps instead of running under the view toolbar on the right (Participants,
    // Navigate, Full screen: ~24rem) when the canvas is narrow.
    <Panel position='top-left' className='bpmn-chrome bpmn-canvas-toolbar flex max-w-[calc(100%-25rem)] flex-wrap items-center gap-0.5 rounded-lg border border-base-300 bg-base-100 p-1 shadow-sm'>
      <Tool icon='lane' label={t('add_lane')} onClick={onAddLane} testId='bpmn-add-lane' />
      {onToggleOrientation && <Tool icon='swap' label={t(`orientation_${next}`)} title={t('switch_orientation')} onClick={onToggleOrientation} testId='bpmn-orientation' />}
      <Tool icon='layout' label={t('auto_layout')} title={t('auto_layout_hint')} onClick={onAutoLayout} testId='bpmn-auto-layout' />
      <Tool icon='arrowRight' label={t('connect')} onClick={onConnect} active={connecting} testId='bpmn-connect' />
      {onImport && (
        <>
          <span className='mx-1 h-5 w-px bg-base-300' />
          <Tool icon='upload' label={t('import_bpmn')} onClick={onImport} />
        </>
      )}
    </Panel>
  )
}

export function ViewToolbar ({ t, editable, onParticipants, participantsOpen, onProperties, propertiesOpen, navigating, onNavigate, fullscreen, onFullscreen }) {
  return (
    <Panel position='top-right' className='bpmn-chrome bpmn-view-toolbar flex items-center gap-1'>
      {onProperties && (
        <button type='button' className={`btn btn-sm gap-1 border-base-300 bg-base-100 font-normal shadow-sm ${propertiesOpen ? 'btn-active' : ''}`} onClick={onProperties} aria-pressed={String(Boolean(propertiesOpen))} title={t('properties')} data-testid='bpmn-properties-toggle'>
          <Icon name='pencil' size={15} /><span className='bpmn-tool-label'>{t('properties')}</span>
        </button>
      )}
      {onParticipants && (
        <button type='button' className={`btn btn-sm gap-1 border-base-300 bg-base-100 font-normal shadow-sm ${participantsOpen ? 'btn-active' : ''}`} onClick={onParticipants}>
          <Icon name='users' size={15} /><span className='bpmn-tool-label'>{t('participants')}</span>
        </button>
      )}
      {editable && (
        <button type='button' className={`btn btn-sm gap-1 border-base-300 bg-base-100 font-normal shadow-sm ${navigating ? 'btn-active text-primary' : ''}`} onClick={onNavigate} aria-pressed={String(navigating)}>
          <Icon name='move' size={15} /><span className='bpmn-tool-label'>{t('navigate')}</span>
        </button>
      )}
      <button type='button' className='btn btn-sm gap-1 border-base-300 bg-base-100 font-normal shadow-sm' onClick={onFullscreen}>
        <Icon name={fullscreen ? 'minimize' : 'maximize'} size={15} /><span className='bpmn-tool-label'>{t(fullscreen ? 'exit_fullscreen' : 'fullscreen')}</span>
      </button>
    </Panel>
  )
}
