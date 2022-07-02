export const toFloat = number => {
  return parseFloat(number.length === 0 ? '0' : number.replace(/,/g, ''))
}

export const toInt = number => {
  return parseInt(number.length === 0 ? '0' : number.replace(/,/g, ''))
}
