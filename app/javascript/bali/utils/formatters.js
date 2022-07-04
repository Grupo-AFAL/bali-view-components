export const toFloat = number => {
  return parseFloat(sanitizeNumber(number))
}

export const toInt = number => {
  return parseInt(sanitizeNumber(number))
}

const sanitizeNumber = number => {
  return number.length === 0 ? '0' : number.replace(/,/g, '')
}
