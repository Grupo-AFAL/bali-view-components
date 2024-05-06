import { toInt, toFloat } from '../../app/assets/javascripts/bali/utils/formatters'

describe('toInt', () => {
  it('converts an empty string to 0', () => {
    expect(toInt('')).to.equal(0)
  })

  it('converts a string to an integer', () => {
    expect(toInt('123')).to.equal(123)
  })

  it('converts a string with commas to an integer', () => {
    expect(toInt('1,000')).to.equal(1000)
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
    expect(toFloat('1,000.12')).to.equal(1000.12)
  })
})
