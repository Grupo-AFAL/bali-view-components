export const toFloat = number => {
  return parseFloat(sanitizeNumber(number))
}

export const toInt = number => {
  return parseInt(sanitizeNumber(number))
}

export const toBool = boolean => {
  if (['false', 'f', '0'].includes(boolean)) return false
  return Boolean(boolean)
}

const sanitizeNumber = number => {
  return number.length === 0 ? '0' : number.replace(/,/g, '')
}
