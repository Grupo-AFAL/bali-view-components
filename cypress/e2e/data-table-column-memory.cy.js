// La memoria por dispositivo del selector de columnas registra las DECISIONES del usuario, y
// una decisión es una diferencia: el estado que dejó en pantalla contra los defaults que el
// servidor declaraba en ese momento. Con la polaridad vieja —una lista de índices visibles— el
// controlador no podía distinguir «esta columna la escondí» de «esta columna no existía cuando
// guardé», y contestaba lo mismo a las dos: oculta. Toda columna agregada después de la primera
// visita nacía invisible para quien ya tenía preferencias, en silencio (#1144).
//
// La memoria es IMPLÍCITA (nadie la pidió), así que donde no hay decisión gana el default del
// servidor — y eso vale también para la columna que el anfitrión declaró `visible: false` y el
// usuario nunca tocó: registrarla como preferencia suya es el mismo defecto, una talla menos.
// Una vista guardada es lo contrario —una elección explícita de columnas— y sigue viajando como
// lista de VISIBLES: eso es lo que fija el anteúltimo bloque.
//
// Este spec es TODA la cobertura del arreglo: el cambio es JS puro y el repo no tiene banco de
// pruebas unitarias de JS, así que Minitest no puede probarlo.
describe('DataTable: memoria del selector de columnas', () => {
  const visitWith = (url, key, value) =>
    cy.visit(url, {
      onBeforeLoad (win) {
        if (value !== null) win.localStorage.setItem(key, value)
      }
    })

  const storedAt = (key) => cy.window().then((win) => win.localStorage.getItem(key))
  const parsedAt = (key) => storedAt(key).then((raw) => JSON.parse(raw))

  // Cuatro columnas (0 Name · 1 Status · 2 Amount · 3 Created At), las cuatro visibles por
  // default. Una memoria que sólo nombra 0..2 es exactamente el caso del issue: «Created At» es
  // la columna que se agregó después.
  describe('con las cuatro columnas visibles por default', () => {
    const key = 'bali:columns:toolbar-demo'
    const listing = '#toolbar-demo'
    const url = '/bali/data_table/with_toolbar_buttons'

    const visit = (value = null) => visitWith(url, key, value)
    const header = (index) => cy.get(`${listing} thead th`).eq(index)
    const box = (index) =>
      cy.get(`${listing} [data-controller~="column-selector"] input[data-column-index="${index}"]`)
    const stored = () => parsedAt(key)

    describe('formato viejo (array pelado de índices visibles)', () => {
      it('deja nacer visible la columna que la memoria no conocía', () => {
        visit('[0,1,2]')

        header(3).should('be.visible').and('contain', 'Created At')
        box(3).should('be.checked')
      })

      it('conserva la columna que el usuario había escondido', () => {
        visit('[0,2,3]')

        header(1).should('not.be.visible')
        box(1).should('not.be.checked')
        header(0).should('be.visible')
        header(2).should('be.visible')
        header(3).should('be.visible')
      })

      // Lo único que un array pelado DEMUESTRA conocer es hasta su índice más alto: de ahí para
      // arriba no se puede afirmar que la columna existiera. Tampoco registraba qué declaraba el
      // servidor, así que la línea base sale de la declaración vigente. La migración escribe las
      // dos listas y corre una sola vez.
      it('lo reescribe completo y la segunda lectura no lo vuelve a tocar', () => {
        visit('[0,2,3]')

        stored().should('deep.equal', {
          v: 2, hidden: [1], known: [0, 1, 2, 3], serverHidden: []
        })

        cy.reload()

        header(1).should('not.be.visible')
        header(3).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [1], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      // El costo medido de la inferencia, fijado para que nadie lo «mejore» sin darse cuenta:
      // esconder la ÚLTIMA columna es indistinguible de no haberla conocido, así que vuelve UNA
      // vez — y a partir de ahí la preferencia se recuerda como cualquier otra.
      it('devuelve una sola vez la última columna escondida', () => {
        visit('[0,1,2]')

        header(3).should('be.visible')

        box(3).uncheck({ force: true })
        header(3).should('not.be.visible')
        cy.reload()

        header(3).should('not.be.visible')
        box(3).should('not.be.checked')
      })

      // Un valor vacío no demuestra conocer ninguna columna: no hay nada que migrar.
      it('vuelve a los defaults cuando el valor viejo no nombra ninguna columna', () => {
        visit('[]')

        header(0).should('be.visible')
        header(3).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      // 256 es el primer índice que la guarda tiene que rechazar, y por eso la semilla es ése
      // y no uno cualquiera: con `<=` en lugar de `<` el techo aceptaba 257 índices, este
      // valor pasaba el filtro y la inferencia escondía la tabla entera.
      it('ignora un índice fuera del techo y no esconde la tabla', () => {
        visit('[256]')

        header(0).should('be.visible')
        header(3).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      // Y uno absurdo escrito por cualquier otra cosa no puede armar un array de mil millones
      // de entradas: se ignora y la página sigue respondiendo.
      it('ignora un índice absurdo sin colgar la página', () => {
        visit('[999999999]')

        header(0).should('be.visible')
        header(3).should('be.visible')
      })
    })

    describe('formato v2', () => {
      it('recuerda la columna que el usuario escondió', () => {
        visit(JSON.stringify({ v: 2, hidden: [3], known: [0, 1, 2, 3], serverHidden: [] }))

        header(3).should('not.be.visible')
        box(3).should('not.be.checked')
        header(0).should('be.visible')
      })

      it('deja nacer visible una columna que la memoria no conoce', () => {
        visit(JSON.stringify({ v: 2, hidden: [1], known: [0, 1, 2], serverHidden: [] }))

        header(1).should('not.be.visible')
        header(3).should('be.visible')
        box(3).should('be.checked')
      })

      // LA OTRA MITAD DEL ARREGLO. La memoria dice que la columna 3 estaba oculta, pero también
      // que el servidor la declaraba oculta: las dos coinciden, así que nadie decidió nada. El
      // anfitrión cambió de opinión —acá la declara visible— y ese cambio SÍ llega.
      it('no esconde una columna que estaba oculta porque el servidor lo decía', () => {
        visit(JSON.stringify({ v: 2, hidden: [3], known: [0, 1, 2, 3], serverHidden: [3] }))

        header(3).should('be.visible')
        box(3).should('be.checked')
      })

      // `force`: el panel lo abre el `:focus-within` de daisyUI, así que la casilla no es
      // accionable con el menú cerrado. Lo que importa es el `change` que dispara.
      it('escribe lo oculto al esconder y lo borra al volver a mostrar', () => {
        visit()

        box(1).uncheck({ force: true })
        header(1).should('not.be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [1], known: [0, 1, 2, 3], serverHidden: []
        })

        box(1).check({ force: true })
        header(1).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      it('sanea un valor con entradas que no son índices', () => {
        visit(JSON.stringify({
          v: 2, hidden: ['1', 'x', -3, 1], known: [0, 1, 2, 3], serverHidden: []
        }))

        header(1).should('not.be.visible')
        header(0).should('be.visible')
        header(3).should('be.visible')
      })

      // Fallo seguro ante un formato futuro: se vuelve a los defaults del servidor y NO se pisa
      // el valor, que la versión que lo escribió sí sabe leer.
      it('ignora una versión que no conoce y no la sobrescribe', () => {
        const future = JSON.stringify({ v: 3, hidden: [1], known: [0, 1, 2, 3] })
        visit(future)

        header(1).should('be.visible')
        header(3).should('be.visible')
        storedAt(key).should('equal', future)
      })
    })
  })

  // El preview con una columna que el ANFITRIÓN declara apagada (`with_column(visible: false)`).
  // Es la rama donde la memoria puede reclamar de más: la columna nace oculta sin que el usuario
  // toque nada, y si eso se registra como preferencia suya, un `visible: true` posterior del
  // anfitrión no le llega nunca — el mismo defecto de #1144 con otro disfraz.
  describe('con una columna que el anfitrión declara oculta', () => {
    const key = 'bali:columns:optional-demo'
    const listing = '#optional-demo'
    const url = '/bali/data_table/with_optional_column'

    const visit = (value = null) => visitWith(url, key, value)
    const header = (index) => cy.get(`${listing} thead th`).eq(index)
    const box = (index) =>
      cy.get(`${listing} [data-controller~="column-selector"] input[data-column-index="${index}"]`)
    const stored = () => parsedAt(key)

    it('la rinde oculta y sin memoria no escribe nada', () => {
      visit()

      header(3).should('not.be.visible')
      box(3).should('not.be.checked')
      storedAt(key).should('equal', null)
    })

    // La escritura de la migración es la que mordía: corre sola, sin que el usuario toque nada.
    // Que la 3 esté en las DOS listas es lo que dice «acá no decidió nadie».
    it('al migrar no la registra como decisión del usuario', () => {
      visit('[0,1,2]')

      header(3).should('not.be.visible')
      stored().should('deep.equal', {
        v: 2, hidden: [3], known: [0, 1, 2, 3], serverHidden: [3]
      })
    })

    // Y el toggle tampoco la arrastra: esconder la 1 no convierte a la 3 en preferencia.
    it('al esconder otra columna tampoco la arrastra', () => {
      visit()

      box(1).uncheck({ force: true })
      header(1).should('not.be.visible')
      stored().should('deep.equal', {
        v: 2, hidden: [1, 3], known: [0, 1, 2, 3], serverHidden: [3]
      })
    })

    // La decisión contraria SÍ se recuerda: encenderla es una elección tan explícita como
    // apagar cualquier otra, y sobrevive a la recarga.
    it('recuerda que el usuario la encendió', () => {
      visit()

      box(3).check({ force: true })
      header(3).should('be.visible')
      stored().should('deep.equal', {
        v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: [3]
      })

      cy.reload()

      header(3).should('be.visible')
      box(3).should('be.checked')
    })
  })

  // Una tabla `selectable:` mete un `<th>` REAL en el índice 0 —la casilla de seleccionar— que
  // el selector no declara: el preview canónico declara 1..5. Es el punto donde afal-apps ya se
  // quemó, y el formato viejo lo cruza de lleno, porque de un array pelado se infiere el rango
  // 0..techo y ahí el 0 entra sin haber sido nunca una columna alternable.
  describe('con una tabla selectable, donde el índice 0 no es una columna', () => {
    const key = 'bali:columns:lookbook_movies'
    const listing = '#lookbook_movies'
    const url = '/bali/data_table/complete'

    it('no toca la casilla de selección al migrar, ni la anota como columna', () => {
      visitWith(url, key, '[1,2,4,5]')

      // La columna de selección sobrevive: sólo se aplica visibilidad sobre las casillas que el
      // selector declara, nunca sobre el rango inferido.
      cy.get(`${listing} thead th`).eq(0).should('be.visible')
      cy.get(`${listing} thead th`).eq(3).should('not.be.visible')
      cy.get(`${listing} thead th`).eq(1).should('be.visible')
      cy.get(`${listing} thead th`).eq(5).should('be.visible')

      // Y el valor reescrito toma `known` de las casillas, no del rango: el 0 no queda anotado
      // como columna que la memoria conoce.
      parsedAt(key).should('deep.equal', {
        v: 2, hidden: [3], known: [1, 2, 3, 4, 5], serverHidden: []
      })
    })
  })

  // Con una vista guardada aplicada manda la vista: la memoria del dispositivo ni se restaura ni
  // se migra en esa carga. La vista 2 del preview registra las columnas [0, 2].
  describe('con una vista guardada aplicada', () => {
    const key = 'bali:columns:saved-views-preview'
    const listing = '#saved-views-preview'
    const url = '/bali/data_table/with_saved_views?saved_view=2'

    it('no restaura la memoria del dispositivo ni la migra', () => {
      visitWith(url, key, '[0,1,2,3]')

      cy.get(`${listing} thead th`).eq(2).should('be.visible')
      cy.get(`${listing} thead th`).eq(1).should('not.be.visible')
      cy.get(`${listing} thead th`).eq(3).should('not.be.visible')
      storedAt(key).should('equal', '[0,1,2,3]')
    })
  })

  // El OTRO lector de la misma llave. Sin selector en pantalla (tarjetas, calendario) el
  // controlador de vistas guardadas cae a la memoria del dispositivo para no guardar una vista
  // sin columnas — y el payload que viaja a `bali_saved_views.payload` sigue siendo una lista
  // de índices VISIBLES, que es lo que `apply_visible_columns` lee del otro lado.
  describe('vistas guardadas en modo tarjetas', () => {
    const gridUrl = '/bali/data_table/complete?view=grid'
    const gridKey = 'bali:columns:lookbook_movies'

    // El submit se intercepta en fase de captura: preventDefault frena a Turbo y al navegador
    // sin impedir que corra la acción de Stimulus, que escucha sobre el propio form.
    const visitGrid = (value) =>
      cy.visit(gridUrl, {
        onBeforeLoad (win) {
          win.localStorage.setItem(gridKey, value)
          win.addEventListener('submit', (event) => event.preventDefault(), true)
        }
      })

    // `?? null`: un `.then` que devuelve `undefined` deja pasar el subject anterior, y la
    // aserción compararía contra el JSON crudo en vez de fallar por columnas ausentes.
    const payloadAfterSubmit = (value) => {
      visitGrid(value)

      cy.get('[data-saved-views-target="saveForm"] form').then(($form) => {
        $form[0].dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
      })

      return cy.get('[data-saved-views-target="payload"]').invoke('val')
        .then((raw) => JSON.parse(raw).columns ?? null)
    }

    it('traduce el formato v2 a la lista de visibles', () => {
      payloadAfterSubmit(JSON.stringify({
        v: 2, hidden: [3], known: [1, 2, 3, 4, 5], serverHidden: []
      })).should('deep.equal', [1, 2, 4, 5])
    })

    it('sigue leyendo el formato viejo tal cual', () => {
      payloadAfterSubmit('[1,2,4,5]').should('deep.equal', [1, 2, 4, 5])
    })

    // Sin selector en pantalla no hay quien reescriba: la llave vieja sigue intacta hasta que
    // alguien vuelve al modo tabla. La guía y el CHANGELOG lo dicen con esa condición.
    it('no migra la llave, porque no hay selector que la reescriba', () => {
      visitGrid('[1,2,4,5]')

      cy.get('[data-saved-views-target="payload"]').should('exist')
      storedAt(gridKey).should('equal', '[1,2,4,5]')
    })
  })
})
