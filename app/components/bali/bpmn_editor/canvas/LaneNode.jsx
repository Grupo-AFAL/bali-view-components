import { Fragment, memo } from 'react'
import { NodeResizeControl } from '@xyflow/react'
import { IssueMarker } from '../shapes.jsx'
import { MIN_LANE_SIZE } from '../model/geometry.js'
import { useCanvas } from './CanvasContext.js'
import { DIFF_MARKS, diffMark } from './diffMarks.js'

// A lane: a header that names the participant (and is the drag handle) and a
// body that lets pointer events through to the pane (flow.css), so dragging
// inside a lane pans the canvas and the nodes on it stay reachable.
//
// Two resize controls: the MAIN-axis one changes this lane's size, the
// CROSS-axis one the length every lane shares.
function LaneNode ({ id, data, selected, width, height }) {
  const canvas = useCanvas()
  const { lane, orientation, header, issue, diff, diffReasons } = data
  const mark = diff ? DIFF_MARKS[diffMark(diff, diffReasons)] : null
  const horizontal = orientation === 'horizontal'
  const external = lane.kind === 'external'
  const name = lane.name || canvas.t('lane_unnamed')
  const editable = canvas.editable
  const renaming = canvas.renamingId === id
  return (
    <div
      className={`bpmn-lane bpmn-lane-${orientation}${external ? ' is-external' : ''}${selected ? ' is-selected' : ''}${canvas.highlightId === id ? ' is-highlighted' : ''}${diff ? ` bpmn-diff-${diff}` : ''}`}
      data-testid='bpmn-lane'
    >
      <div
        className='bpmn-lane-header'
        style={horizontal ? { width: header } : { height: header }}
        title={editable ? canvas.t('lane_drag') : external ? `${name}, ${canvas.t('lane_external').toLowerCase()}` : name}
        onDoubleClick={editable ? (event) => { event.stopPropagation(); canvas.startRename(id) } : undefined}
      >
        {renaming
          ? canvas.renderRename(lane, true)
          : (
            <span className='bpmn-lane-name'>
              {mark && <span className={`bpmn-diff-chip is-${mark.tone}`} data-testid='bpmn-diff-mark' title={canvas.t(mark.label)}>{mark.symbol}</span>}
              <span className='bpmn-lane-title'>{name}</span>
              {/* Said, not shown: the grey lane and the legend already show it,
                  and its line took room from the lane's name. */}
              {external && <span className='sr-only' data-testid='bpmn-lane-external-name'>{`, ${canvas.t('lane_external').toLowerCase()}`}</span>}
            </span>
            )}
        {issue && (
          <svg className='bpmn-lane-issue' width={20} height={18} aria-hidden='true'>
            <IssueMarker x={10} y={9} />
          </svg>
        )}
      </div>
      {editable && (
        // Keyed on the size: a NodeResizeControl keeps the box it measured when
        // it mounted, so after a resize the next drag started from the old
        // geometry and did nothing (gobierno-corporativo hit the same, and
        // remounts it the same way).
        <Fragment key={`${width}x${height}`}>
          <NodeResizeControl
            position={horizontal ? 'bottom' : 'right'}
            variant='line'
            className='bpmn-lane-resize'
            minHeight={horizontal ? MIN_LANE_SIZE.horizontal : 80}
            minWidth={horizontal ? 200 : MIN_LANE_SIZE.vertical}
            onResizeEnd={(_event, params) => canvas.onLaneResize(id, 'main', params)}
          />
          <NodeResizeControl
            position={horizontal ? 'right' : 'bottom'}
            variant='line'
            className='bpmn-lane-resize'
            minHeight={80}
            minWidth={80}
            onResize={(_event, params) => canvas.onLaneResizing(id, params)}
            onResizeEnd={(_event, params) => canvas.onLaneResize(id, 'cross', params)}
          />
        </Fragment>
      )}
    </div>
  )
}

export default memo(LaneNode)
