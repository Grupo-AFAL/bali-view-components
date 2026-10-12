// Fills in the `%{name}` placeholders a Rails translation keeps when it is fetched without
// values. The replacement is a function: as a string, a `$&` in a value — a file name — would
// be read as a pattern and turn into the placeholder it replaces.
export function interpolate (template, values = {}) {
  return Object.entries(values).reduce(
    (text, [name, value]) => text.replaceAll(`%{${name}}`, () => value),
    template
  )
}
