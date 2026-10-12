import { interpolate } from '../../app/assets/javascripts/bali/utils/interpolate'

// #1409 — FileInput, DirectUpload and the BlockEditor fill a translation's Rails placeholders
// with what only the browser knows, a file name among them.
describe('interpolate', () => {
  it('writes a value as it is, even one String#replace would read as a pattern', () => {
    expect(interpolate('Eliminar %{name}', { name: "a $& b $$ c $' d" }))
      .to.eq("Eliminar a $& b $$ c $' d")
  })

  it('fills every occurrence of every placeholder', () => {
    expect(interpolate('%{a} %{b} %{a}', { a: 1, b: 'x' })).to.eq('1 x 1')
  })
})
