// The variant of the "contains" predicate this server's ransack gets from Bali (#1530): `cont` up
// to ransack 5, `i_cont` from 6. A spec that names the quick search's box or a field the panel
// submits asks for it here instead of writing it down, so it holds under either.
//
// It is the first text operator Ruby hands the condition controller in its translations, the one
// `condition_controller.js#reset` goes back to, read off a page that renders a panel row. What the
// spec then checks is that the box and the panel send the variant the page itself offers; which
// variant each ransack must offer is `test/bali/search_config_test.rb`'s to pin.
let contains

export const containsPredicate = () => {
  if (contains) return cy.wrap(contains, { log: false })

  return cy.request('/bali/filters/all_field_types?popover=false').then(({ body }) => {
    const row = new DOMParser().parseFromString(body, 'text/html').querySelector('[data-controller="condition"]')
    contains = JSON.parse(row.getAttribute('data-condition-translations-value')).operators.text[0].value

    return contains
  })
}
