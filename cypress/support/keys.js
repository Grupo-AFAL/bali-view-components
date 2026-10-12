// Shift+Tab through the browser's own keyboard path, over CDP. `cy.press` takes no modifiers,
// and a synthetic keydown moves no focus: the step into an iframe, or the one a focus trap
// cancels, is the browser's default action.
export const shiftTab = () => {
  const key = { key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9, nativeVirtualKeyCode: 9, modifiers: 8 }
  const send = (type) => Cypress.automation('remote:debugger:protocol', {
    command: 'Input.dispatchKeyEvent',
    params: { type, ...key }
  })

  return cy.then(() => send('rawKeyDown').then(() => send('keyUp')))
}
