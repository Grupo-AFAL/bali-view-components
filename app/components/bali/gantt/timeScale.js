// Pure time-scale helpers for the Gantt island (#705, ported from afal-apps).
// The server is authoritative over dates; these helpers only translate ISO
// dates <-> horizontal pixel positions to paint bars. `pxPerDay` implements
// the zoom as a DATA transform, not React Flow's 2D zoom (which scales both
// axes and is pinned to 1 by the canvas).
//
// These densities are the island's alone since #970 removed the server-rendered
// board: Ruby no longer computes a pixel. What still crosses the boundary is the
// zoom NAMES — Bali::Gantt::TimeScale resolves `:auto` to one of them and hands
// it over as `initialZoom`, and a test compares both lists.
import {
  differenceInCalendarDays,
  parseISO,
  addDays,
  formatISO,
  startOfWeek,
  startOfMonth,
  addWeeks,
  addMonths,
  format,
  isSameDay
} from 'date-fns'
import { es } from 'date-fns/locale'

// date-fns formats in English by default; `es` is the one non-default locale
// the AFAL apps need. The island sets it once from its `dateLocale` prop.
const LOCALES = { es }
let dateLocale

export function setDateLocale (code) {
  dateLocale = LOCALES[code]
}

// Calendar days between two ISO dates (b - a). Negative when b < a.
export function daysBetween (aIso, bIso) {
  return differenceInCalendarDays(parseISO(bIso), parseISO(aIso))
}

// Inclusive duration in days of an ISO range (both ends counted).
export function durationDays (startsOn, endsOn) {
  if (!startsOn) return 1
  return Math.max(1, daysBetween(startsOn, endsOn || startsOn) + 1)
}

// X position (px) of a date relative to the window start.
export function dateToX (isoDate, windowStartIso, pxPerDay) {
  return daysBetween(windowStartIso, isoDate) * pxPerDay
}

// ISO date (day only) for a given X position. Inverse of dateToX.
export function xToDate (x, windowStartIso, pxPerDay) {
  const days = Math.round(x / pxPerDay)
  return formatISO(addDays(parseISO(windowStartIso), days), { representation: 'date' })
}

// Ticks of the time axis: [{ key, label, x, width }] to paint the header
// bands — day / week / month depending on the zoom. `x`/`width` share the
// bars' coordinates (window offset × pxPerDay), so header and bars share the
// viewport's translateX.
export function timeTicks (windowStartIso, windowEndIso, pxPerDay, unit, originIso = windowStartIso) {
  if (!windowStartIso || !windowEndIso) return []
  const start = parseISO(windowStartIso)
  const end = parseISO(windowEndIso)
  if (end < start) return []

  const origin = parseISO(originIso)
  const ticks = []
  const xOf = (date) => differenceInCalendarDays(date, origin) * pxPerDay

  if (unit === 'day') {
    let cursor = start
    while (cursor <= end) {
      ticks.push({
        key: cursor.getTime(),
        label: format(cursor, 'd', { locale: dateLocale }),
        x: xOf(cursor),
        width: pxPerDay
      })
      cursor = addDays(cursor, 1)
    }
  } else if (unit === 'month') {
    let cursor = startOfMonth(start)
    while (cursor <= end) {
      const next = addMonths(cursor, 1)
      const segStart = cursor < start ? start : cursor
      ticks.push({
        key: cursor.getTime(),
        label: format(cursor, 'MMM yyyy', { locale: dateLocale }),
        x: xOf(segStart),
        width: differenceInCalendarDays(next, segStart) * pxPerDay
      })
      cursor = next
    }
  } else {
    // week (default): weeks start on Monday.
    let cursor = startOfWeek(start, { weekStartsOn: 1 })
    while (cursor <= end) {
      const next = addWeeks(cursor, 1)
      const segStart = cursor < start ? start : cursor
      ticks.push({
        key: cursor.getTime(),
        label: format(segStart, 'd MMM', { locale: dateLocale }),
        x: xOf(segStart),
        width: differenceInCalendarDays(next, segStart) * pxPerDay
      })
      cursor = next
    }
  }

  return ticks
}

// CONTEXT band (upper header tier): groups the range into month segments
// (day/week zoom) or year segments (month zoom) so the user knows which
// month/year the ticks belong to. Same coordinates as the bars.
export function timeBands (windowStartIso, windowEndIso, pxPerDay, unit, originIso = windowStartIso) {
  if (!windowStartIso || !windowEndIso) return []
  const start = parseISO(windowStartIso)
  const end = parseISO(windowEndIso)
  if (end < start) return []

  const origin = parseISO(originIso)
  const bands = []
  const xOf = (date) => differenceInCalendarDays(date, origin) * pxPerDay

  if (unit === 'month') {
    // Upper tier = year.
    let cursor = new Date(start.getFullYear(), 0, 1)
    while (cursor <= end) {
      const next = new Date(cursor.getFullYear() + 1, 0, 1)
      const segStart = cursor < start ? start : cursor
      bands.push({
        key: cursor.getFullYear(),
        label: format(cursor, 'yyyy', { locale: dateLocale }),
        x: xOf(segStart),
        width: differenceInCalendarDays(next, segStart) * pxPerDay
      })
      cursor = next
    }
  } else {
    // day / week → upper tier = month.
    let cursor = startOfMonth(start)
    while (cursor <= end) {
      const next = addMonths(cursor, 1)
      const segStart = cursor < start ? start : cursor
      bands.push({
        key: cursor.getTime(),
        label: format(cursor, 'MMMM yyyy', { locale: dateLocale }),
        x: xOf(segStart),
        width: differenceInCalendarDays(next, segStart) * pxPerDay
      })
      cursor = next
    }
  }
  return bands
}

// Adds n days to an ISO date and returns ISO (day only). Used to extend the
// axis beyond the data range so it fills the canvas.
export function addDaysIso (iso, n) {
  if (!iso) return iso
  return formatISO(addDays(parseISO(iso), n), { representation: 'date' })
}

// Short "d MMM" label (e.g. "6 Jun") for the table's dates column.
export function fmtDayMonth (iso) {
  if (!iso) return ''
  return format(parseISO(iso), 'd MMM', { locale: dateLocale })
}

// Weekend bands: one faint rectangle per Saturday/Sunday for calendar texture
// at day/week zoom. Not applicable at month zoom.
export function weekendBands (windowStartIso, windowEndIso, pxPerDay, unit, originIso = windowStartIso) {
  if (unit === 'month') return []
  if (!windowStartIso || !windowEndIso) return []
  const start = parseISO(windowStartIso)
  const end = parseISO(windowEndIso)
  if (end < start) return []

  const origin = parseISO(originIso)
  const bands = []
  let cursor = start
  while (cursor <= end) {
    const dow = cursor.getDay() // 0 Sunday .. 6 Saturday
    if (dow === 0 || dow === 6) {
      bands.push({
        key: cursor.getTime(),
        x: differenceInCalendarDays(cursor, origin) * pxPerDay,
        width: pxPerDay
      })
    }
    cursor = addDays(cursor, 1)
  }
  return bands
}

// X (px) of the "today" line inside [start,end], relative to `originIso`, or
// null when today falls outside the range.
export function todayX (windowStartIso, windowEndIso, pxPerDay, originIso = windowStartIso) {
  if (!windowStartIso || !windowEndIso) return null
  const start = parseISO(windowStartIso)
  const end = parseISO(windowEndIso)
  const today = new Date()
  if (today < start && !isSameDay(today, start)) return null
  if (today > end && !isSameDay(today, end)) return null
  return differenceInCalendarDays(today, parseISO(originIso)) * pxPerDay
}
