// Lengths and cuts in characters, not UTF-16 units: half an emoji is a lone
// surrogate, which encodeURIComponent refuses (the image export) and SVG
// paints as U+FFFD.
export const textLength = (text) => Array.from(text).length
export const cutText = (text, length) => Array.from(text).slice(0, Math.max(0, length)).join('')
