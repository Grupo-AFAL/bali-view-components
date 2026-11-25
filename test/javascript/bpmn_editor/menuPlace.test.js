import { test } from 'node:test'
import assert from 'node:assert/strict'
import { menuPlace, MENU_PLACES, MENU_SIZE, MENU_OFFSET } from '../../../app/components/bali/bpmn_editor/canvas/menuPlace.js'

const PANE = { w: 1000, h: 660 }
const me = { x: 300, y: 300, w: 90, h: 40 }
const sideOf = (index) => (index < 0 ? null : MENU_PLACES[index].slice(0, 2).join(' '))
const at = (x, y, w = 60, h = 40) => ({ x, y, w, h })

test('the quick menu opens to the right of the element when nothing stands there', () => {
  assert.equal(sideOf(menuPlace(me, [], PANE)), 'right start')
  assert.equal(sideOf(menuPlace(me, [at(100, 100)], PANE)), 'right start')
})

// The case of the issue: a gateway 130 px on, inside the 272 px the menu takes.
test('with a neighbour where it would open, it goes to the next place that covers none', () => {
  const gateway = at(me.x + me.w + 80, me.y)
  assert.equal(sideOf(menuPlace(me, [gateway], PANE)), 'left start')
  const before = at(me.x - 120, me.y)
  assert.equal(sideOf(menuPlace(me, [gateway, before], PANE)), 'bottom start')
  const under = at(me.x + 150, me.y + me.h + 30)
  assert.equal(sideOf(menuPlace(me, [gateway, before, under], PANE)), 'bottom end')
  const underLeft = at(me.x - 100, me.y + me.h + 30)
  assert.equal(sideOf(menuPlace(me, [gateway, before, under, underLeft], PANE)), 'top start')
})

test('a place that would leave the canvas, or go under the properties panel, is not one', () => {
  const edge = { ...me, x: PANE.w - me.w - MENU_OFFSET - MENU_SIZE.w + 1 }
  assert.equal(sideOf(menuPlace(edge, [], PANE)), 'left start')
  assert.equal(sideOf(menuPlace(me, [], { ...PANE, w: 600 })), 'left start')
  assert.equal(sideOf(menuPlace({ ...me, x: 20, y: 20 }, [at(160, 20)], { w: 320, h: 200 })), 'bottom start')
})

test('with every place taken it answers none, and the editor falls back to the side it always used', () => {
  const walls = [at(0, 0, 1000, 290), at(0, 350, 1000, 300), at(0, 290, 290, 60), at(400, 290, 600, 60)]
  assert.equal(menuPlace(me, walls, PANE), -1)
})

// A pan or a zoom runs this again: the menu stays where it is while it still fits there.
test('it stays where it is while that place is free, though one further up the list opens', () => {
  const below = MENU_PLACES.findIndex(([side, align]) => side === 'bottom' && align === 'start')
  assert.equal(menuPlace(me, [], PANE, below), below)
  assert.equal(sideOf(menuPlace(me, [at(me.x + 20, me.y + me.h + 20)], PANE, below)), 'right start')
})
