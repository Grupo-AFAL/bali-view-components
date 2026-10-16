// Toolbar icons, inline like the Gantt island's: the island bundle carries no
// icon set. Paths are Lucide's (ISC licence), 24×24, stroke 2.
const PATHS = {
  plus: 'M5 12h14M12 5v14',
  minus: 'M5 12h14',
  crosshair: 'M12 2v4M12 18v4M2 12h4M18 12h4M12 12m-8 0a8 8 0 1 0 16 0a8 8 0 1 0-16 0',
  selectAll: 'M5 3a2 2 0 0 0-2 2M19 3a2 2 0 0 1 2 2M21 19a2 2 0 0 1-2 2M5 21a2 2 0 0 1-2-2M9 3h1M9 21h1M14 3h1M14 21h1M3 9v1M21 9v1M3 14v1M21 14v1M9 9h6v6H9z',
  undo: 'M9 14 4 9l5-5M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5 5.5 5.5 0 0 1-5.5 5.5H11',
  redo: 'm15 14 5-5-5-5M20 9H9.5A5.5 5.5 0 0 0 4 14.5 5.5 5.5 0 0 0 9.5 20H13',
  download: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3',
  image: 'M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM9 9m-2 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0M21 15l-3.1-3.1a2 2 0 0 0-2.8 0L6 21',
  printer: 'M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2M6 9V3h12v6M6 14h12v8H6z',
  refresh: 'M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8M21 3v5h-5M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16M8 16H3v5',
  save: 'M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2zM17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7M7 3v4a1 1 0 0 0 1 1h7',
  flag: 'M4 22V4a1 1 0 0 1 .4-.8A6 6 0 0 1 8 2c3 0 5 2 7.333 2q2 0 3.067-.8A1 1 0 0 1 20 4v10a1 1 0 0 1-.4.8A6 6 0 0 1 16 16c-3 0-5-2-8-2a6 6 0 0 0-4 1.528',
  alert: 'm21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3M12 9v4M12 17h.01',
  alertCircle: 'M12 12m-10 0a10 10 0 1 0 20 0a10 10 0 1 0-20 0M12 8v4M12 16h.01',
  listChecks: 'm3 17 2 2 4-4M3 7l2 2 4-4M13 6h8M13 12h8M13 18h8',
  lane: 'M3 3h18v18H3zM3 9h18M3 15h18M8 3v18',
  swap: 'M8 3 4 7l4 4M4 7h16M16 21l4-4-4-4M20 17H4',
  layout: 'M3 3h7v7H3zM14 3h7v7h-7zM14 14h7v7h-7zM3 14h7v7H3z',
  arrowRight: 'M5 12h14M12 5l7 7-7 7',
  arrowLeft: 'm12 19-7-7 7-7M19 12H5',
  arrowUp: 'm5 12 7-7 7 7M12 19V5',
  arrowDown: 'M12 5v14M19 12l-7 7-7-7',
  upload: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12',
  users: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 7m-4 0a4 4 0 1 0 8 0a4 4 0 1 0-8 0M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75',
  move: 'M12 2v20M15 19l-3 3-3-3M19 9l3 3-3 3M2 12h20M5 9l-3 3 3 3M9 5l3-3 3 3',
  maximize: 'M8 3H5a2 2 0 0 0-2 2v3M21 8V5a2 2 0 0 0-2-2h-3M3 16v3a2 2 0 0 0 2 2h3M16 21h3a2 2 0 0 0 2-2v-3',
  minimize: 'M8 3v3a2 2 0 0 1-2 2H3M21 8h-3a2 2 0 0 1-2-2V3M3 16h3a2 2 0 0 1 2 2v3M16 21v-3a2 2 0 0 1 2-2h3',
  chevronLeft: 'm15 18-6-6 6-6',
  chevronRight: 'm9 18 6-6-6-6',
  chevronDown: 'm6 9 6 6 6-6',
  x: 'M18 6 6 18M6 6l12 12',
  search: 'M11 11m-8 0a8 8 0 1 0 16 0a8 8 0 1 0-16 0M21 21l-4.3-4.3',
  trash: 'M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2',
  link: 'M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71',
  external: 'M15 3h6v6M10 14 21 3M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6',
  info: 'M12 12m-10 0a10 10 0 1 0 20 0a10 10 0 1 0-20 0M12 16v-4M12 8h.01',
  alignV: 'M12 2v20M8 5h8v5H8zM6 14h12v5H6z',
  alignH: 'M2 12h20M5 8v8h5V8zM14 6v12h5V6z',
  more: 'M12 12h.01M19 12h.01M5 12h.01',
  pencil: 'M21.17 6.81a1 1 0 0 0-3.99-3.99L3.84 16.17a2 2 0 0 0-.5.83l-1.32 4.35a.5.5 0 0 0 .62.62l4.35-1.32a2 2 0 0 0 .83-.5zM15 5l4 4',
  route: 'M6 19m-3 0a3 3 0 1 0 6 0a3 3 0 1 0-6 0M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15M18 5m-3 0a3 3 0 1 0 6 0a3 3 0 1 0-6 0',
  check: 'M20 6 9 17l-5-5',
  note: 'M15.5 3H5a2 2 0 0 0-2 2v14c0 1.1.9 2 2 2h14a2 2 0 0 0 2-2V8.5L15.5 3ZM15 3v6h6',
  compare: 'M18 18m-3 0a3 3 0 1 0 6 0a3 3 0 1 0-6 0M6 6m-3 0a3 3 0 1 0 6 0a3 3 0 1 0-6 0M13 6h3a2 2 0 0 1 2 2v7M11 18H8a2 2 0 0 1-2-2V9'
}

export default function Icon ({ name, size = 16, className = '' }) {
  return (
    <svg
      width={size} height={size} viewBox='0 0 24 24' fill='none' stroke='currentColor' strokeWidth={2}
      strokeLinecap='round' strokeLinejoin='round' className={`shrink-0 ${className}`} aria-hidden='true'
    >
      <path d={PATHS[name]} />
    </svg>
  )
}
