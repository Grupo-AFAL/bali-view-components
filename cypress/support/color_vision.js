// How far apart two colours stay for a reader with a colour-vision deficiency: their distance in
// OKLab (ΔE_OK) after simulating the deficiency with the matrices of Machado, Oliveira and
// Fernandes (2009) at severity 1.0, applied in linear sRGB. Colours come in as the 8-bit sRGB a
// canvas paints, which is what `paintedPixel` (painted_contrast.js) hands back.

const MACHADO = {
  protanopia: [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
  deuteranopia: [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
  tritanopia: [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]]
}

export const DEFICIENCIES = Object.keys(MACHADO)

const linear = (channel) => {
  const v = channel / 255
  return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
}

const clamp = (v) => Math.min(1, Math.max(0, v))

const simulate = (rgb, deficiency) =>
  MACHADO[deficiency].map(([r, g, b]) => clamp(r * rgb[0] + g * rgb[1] + b * rgb[2]))

// Björn Ottosson's linear sRGB to OKLab.
const oklab = ([r, g, b]) => {
  const l = Math.cbrt(0.4122214708 * r + 0.5363288953 * g + 0.0514459929 * b)
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
  return [
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
  ]
}

const distance = ([p, q]) => Math.hypot(p[0] - q[0], p[1] - q[1], p[2] - q[2])

export const cvdDistance = (a, b, deficiency) =>
  distance([a, b].map((rgb) => oklab(simulate(rgb.map(linear), deficiency))))

// The same ΔE_OK for a reader without a deficiency.
export const okDistance = (a, b) => distance([a, b].map((rgb) => oklab(rgb.map(linear))))
