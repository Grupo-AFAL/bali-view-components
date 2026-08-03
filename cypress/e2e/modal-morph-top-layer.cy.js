// Un morph de Turbo le sacaba el atributo `open` a un panel abierto con `showModal()`, y desde
// ahí la página no se podía liberar (#855).
//
// Idiomorph escribe cada atributo que trae el nodo nuevo y BORRA todo el que el viejo tiene y el
// nuevo no. El markup que el server manda para un panel abierto es un panel CERRADO, así que el
// morph se lleva `open` y la clase de apertura. Y quitarle el atributo a un `<dialog>` abierto
// con `showModal()` NO lo saca del top layer: el documento sigue inerte, el UA deja de pintar el
// panel, y `close()` retorna temprano —sin tirar error— sobre un dialog sin el atributo. No queda
// nada que devuelva la página.
//
// Se mide con `element.matches(':modal')`, que es lo que de verdad decide si el resto del
// documento está inerte. Leer clases o el atributo `open` reporta una página sana mientras está
// muerta.
describe('Un morph no puede dejar la página inerte', () => {
  // El dummy vive arriba del path de previews al que apunta `baseUrl`; un `http://localhost:3001`
  // literal ignora CYPRESS_BASE_URL y prueba el server de otro checkout.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin

  const mainDrawer = win => win.document.getElementById('main-drawer')

  const openTheDrawer = () => {
    cy.get('[data-action*="drawer#open"]').first().click()
    cy.get('#main-drawer').should('have.class', 'drawer-open')
    // El contenido llega por fetch; el Cancel que cierra el panel viene con él.
    cy.get('#main-drawer button[data-action*="drawer#close"]').should('exist')
    cy.window().should(win => {
      expect(mainDrawer(win).matches(':modal'), ':modal al abrir').to.equal(true)
    })
  }

  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit(`${appOrigin}/admin/studios`)
    cy.get('#main-drawer').should('exist')
  })

  it('deja fuera del morph al panel que está abierto', () => {
    openTheDrawer()

    // Control: un atributo que el markup del server no trae. Si el morph corrió de verdad se lo
    // lleva, que es exactamente lo que le hacía a `open`. Sin esto, un morph que no llegó a
    // pasar se vería igual que uno que respetó el panel.
    cy.window().then(win => {
      win.document.body.setAttribute('data-morph-probe', '1')
      win.__morphed = false
      win.addEventListener('turbo:morph', () => { win.__morphed = true }, { once: true })
      // La forma más ancha de llegar acá, y la que no depende de que el host escriba nada raro:
      // cualquier `turbo_stream.refresh(method: :morph)` que aterrice con un panel abierto,
      // incluido uno difundido por WebSocket desde otra sesión.
      win.Turbo.renderStreamMessage('<turbo-stream action="refresh" method="morph"></turbo-stream>')
    })

    cy.window().its('__morphed', { timeout: 15000 }).should('equal', true)
    cy.get('body').should('not.have.attr', 'data-morph-probe')

    cy.window().should(win => {
      const drawer = mainDrawer(win)
      expect(drawer.hasAttribute('open'), 'atributo open').to.equal(true)
      expect(drawer.matches(':modal'), ':modal después del morph').to.equal(true)
    })
    cy.get('#main-drawer').should('have.class', 'drawer-open')

    // Y sigue siendo un panel normal: cerrarlo devuelve la página.
    cy.get('#main-drawer button[data-action*="drawer#close"]').click()
    cy.window().should(win => {
      expect(mainDrawer(win).matches(':modal'), ':modal al cerrar').to.equal(false)
    })
  })

  it('libera la página aunque el panel ya haya quedado varado en el top layer', () => {
    // La prevención sólo cubre los paneles que un controlador ve en el momento del morph. Esto
    // cubre al que ya quedó roto — por una versión anterior, o por cualquier otro código que le
    // saque el atributo.
    openTheDrawer()

    cy.window().then(win => {
      const drawer = mainDrawer(win)
      const trigger = win.document.querySelector('[data-action*="drawer#open"]')
      const box = trigger.getBoundingClientRect()
      win.__triggerPoint = [box.left + box.width / 2, box.top + box.height / 2]

      // Exactamente lo que el morph le hace al atributo que el markup nuevo no trae.
      drawer.removeAttribute('open')

      expect(drawer.open, 'prop open').to.equal(false)
      expect(drawer.matches(':modal'), 'sigue en el top layer').to.equal(true)

      // El síntoma, medido donde se ve: el punto del botón de la página no le llega al botón.
      // Sobre un `<dialog>` pelado ahí `elementFromPoint` devuelve `HTML` —el documento queda
      // inerte hasta para el hit-testing—, pero el drawer de Bali conserva `display: block`
      // cerrado (es lo que le permite salir deslizándose en vez de desaparecer), así que su
      // `.drawer-overlay` a pantalla completa sigue siendo lo primero que se toca. El panel
      // no se ve y se queda con la página igual.
      const hit = win.document.elementFromPoint(...win.__triggerPoint)
      expect(drawer.contains(hit), 'el punto del botón cae dentro del panel varado').to.equal(true)
    })

    // `{ force: true }`: el UA dejó de pintar el panel, así que su botón no tiene caja. Es el
    // estado que se está probando, no un atajo para evitar una espera.
    cy.get('#main-drawer button[data-action*="drawer#close"]').click({ force: true })

    cy.window().should(win => {
      expect(mainDrawer(win).matches(':modal'), ':modal después de cerrar').to.equal(false)
    })

    // La prueba de que la página volvió: un click de verdad sobre el botón que estaba tapado,
    // SIN `force`. `cy.click()` falla si algo cubre el objetivo, que es justo el estado del que
    // se viene. Que además reabra el panel muestra que el controlador sigue entero.
    cy.get('[data-action*="drawer#open"]').first().click()
    cy.get('#main-drawer').should('have.class', 'drawer-open')
  })

  it('no interfiere con el morph de un panel cerrado', () => {
    // La cancelación tiene que ser del panel ABIERTO y nada más: congelar el elemento y su
    // subárbol siempre dejaría el panel cerrado sin actualizarse nunca.
    cy.window().then(win => {
      mainDrawer(win).setAttribute('data-morph-probe', '1')
      win.__morphed = false
      win.addEventListener('turbo:morph', () => { win.__morphed = true }, { once: true })
      win.Turbo.renderStreamMessage('<turbo-stream action="refresh" method="morph"></turbo-stream>')
    })

    cy.window().its('__morphed', { timeout: 15000 }).should('equal', true)
    cy.get('#main-drawer').should('not.have.attr', 'data-morph-probe')
  })
})
