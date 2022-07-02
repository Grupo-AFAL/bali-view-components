import { toInt, toFloat } from '../../app/javascript/bali/utils/formatters'

describe('toInt', () => {
  it('converts an empty string to 0', () => {
    expect(toInt('')).to.equal(0)
  })

  it('converts a string to an integer', () => {
    expect(toInt('123')).to.equal(123)
  })

  it('converts a string with commas to an integer', () => {
    expect(toInt('123,000')).to.equal(123000)
  })
})

describe('toFloat', () => {
  it('converts an empty string to 0', () => {
    expect(toFloat('')).to.equal(0)
  })

  it('converts a string to a float', () => {
    expect(toFloat('123.12')).to.equal(123.12)
  })

  it('converts a string with commas to a float', () => {
    expect(toFloat('123,000.12')).to.equal(123000.12)
  })
})
