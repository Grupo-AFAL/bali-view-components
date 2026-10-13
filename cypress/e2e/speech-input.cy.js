// Dictation (#1450). The recognition itself is the browser's and needs a microphone and a
// permission, so what runs here is a DOUBLE of `window.SpeechRecognition`: the controller only
// ever talks to that constructor, and every behaviour worth pinning —what it does with a result,
// with an error, with a keystroke, with a submit— is on this side of it.
//
// What a double cannot say is whether the engine hears anything. That is manual, and the guide
// says so.
describe('Dictation', () => {
  const field = () => cy.get('#dictated')
  const mic = () => cy.get('[data-speech-input-target="button"]').first()
  const status = () => cy.get('[data-speech-input-target="status"]').first()

  // The last double built, so a test can push results and errors into the live session.
  const engine = () => cy.window().then(win => win.__speech)

  // Installed BEFORE the page's JS runs: the controller reads the constructor on connect.
  const visitWith = ({ recognition = true } = {}) =>
    cy.visit('/bali/form/text_area/dictation', {
      onBeforeLoad (win) {
        if (!recognition) {
          delete win.SpeechRecognition
          delete win.webkitSpeechRecognition
          return
        }

        win.SpeechRecognition = function () {
          const listeners = {}
          const self = {
            lang: null,
            continuous: false,
            interimResults: false,
            started: 0,
            stopped: 0,
            aborted: 0,
            addEventListener (name, handler) { (listeners[name] ||= []).push(handler) },
            start () { self.started += 1 },
            stop () { self.stopped += 1 },
            abort () { self.aborted += 1 },
            emit (name, event) { (listeners[name] || []).forEach(handler => handler(event)) },
            // `results` is array-like in the real API, and the controller walks it with
            // `Array.from`: a plain array is the same thing to it.
            say (...phrases) {
              self.emit('result', { results: phrases.map(phrase => [{ transcript: phrase }]) })
            }
          }
          win.__speech = self
          return self
        }
        delete win.webkitSpeechRecognition
      }
    })

  context('where the browser has recognition', () => {
    beforeEach(() => visitWith())

    it('reveals the mic, which the server rendered hidden', () => {
      mic().should('be.visible').and('have.attr', 'aria-pressed', 'false')
    })

    // #1451 review: no language is set unless the field asked for one. Without `lang` the API
    // falls back to the page's own `<html lang>`, which is right far more often than any single
    // default this library could pick for every host — the old `es-MX` had an English host
    // dictating in Spanish.
    it('starts the session and leaves the language to the page', () => {
      mic().click()

      engine().should(speech => {
        expect(speech.started).to.equal(1)
        expect(speech.lang, 'no lang means the page decides').to.equal(null)
        expect(speech.continuous, 'pauses must not end the session').to.equal(true)
        expect(speech.interimResults).to.equal(true)
      })
      mic().should('have.attr', 'aria-pressed', 'true').and('have.class', 'btn-error')
    })

    it('reads the language off the field that was dictated', () => {
      cy.get('#dictated_in_english').parents('.control').find('[data-speech-input-target="button"]').click()

      engine().should(speech => expect(speech.lang).to.equal('en-US'))
    })

    // The API re-emits a phrase as it corrects it, so the field is rebuilt from the WHOLE result
    // list every time. Appending would stutter.
    it('rebuilds the field from every result, not from the last one', () => {
      mic().click()
      engine().then(speech => speech.say('hola'))
      field().should('have.value', 'hola')

      engine().then(speech => speech.say('hola mundo'))
      field().should('have.value', 'hola mundo')
    })

    it('keeps what was already typed before the mic went on', () => {
      field().type('Nota previa.')
      mic().click()
      engine().then(speech => speech.say('y lo dictado'))

      field().should('have.value', 'Nota previa. y lo dictado')
    })

    // The field grows with the dictation: `textarea` re-measures on `input`, and a scripted
    // value fires none, so the controller dispatches it itself.
    it('grows the auto-grow field with what is dictated', () => {
      let before
      field().then($f => { before = $f[0].getBoundingClientRect().height })
      mic().click()
      // `\n` would not do it: the transcript collapses whitespace, because the engine emits
      // words and not layout. What grows the field is a phrase long enough to wrap.
      engine().then(speech => speech.say('una frase larga dictada de corrido '.repeat(25)))

      field().should($f => expect($f[0].getBoundingClientRect().height).to.be.greaterThan(before))
    })

    it('stops when the mic is tapped again', () => {
      mic().click()
      mic().click()

      engine().should(speech => expect(speech.stopped).to.equal(1))
      mic().should('have.attr', 'aria-pressed', 'false').and('have.class', 'btn-ghost')
    })

    // Without this the next result rebuilds the field from `base` and eats the correction. It is
    // covered because the guard is a flag around the controller's own write and not
    // `event.isTrusted`, which no test can produce.
    it('stops when the person types, and leaves the typing alone', () => {
      mic().click()
      engine().then(speech => speech.say('dictado'))
      field().type(' corregido a mano')

      engine().should(speech => expect(speech.aborted).to.equal(1))
      field().should('have.value', 'dictado corregido a mano')
    })

    // A mic left open over a composer that has already been sent. The controller listens for its
    // own form's submit: a `data-action` is one more thing a call site can forget, and forgetting
    // it is not visible.
    // #1451 review: this used to pass with or without the submit listener. The preview POSTs to
    // a route the dummy only answers on GET, so Turbo painted the 404, the controller
    // disconnected, and `disconnect()` ended the session anyway. The submission is cancelled
    // here so the page stays put and the listener is the only thing that can do it.
    it('stops when the form is submitted, without leaving the page', () => {
      cy.get('form').first().then($form => {
        $form[0].addEventListener('submit', event => event.preventDefault())
      })
      mic().click()
      cy.get('button[type="submit"]').first().click()

      engine().should(speech => expect(speech.aborted).to.equal(1))
      mic().should('have.attr', 'aria-pressed', 'false')
      cy.location('pathname').should('eq', '/lookbook/preview/bali/form/text_area/dictation')
    })

    // #1451 review. The two ways a session ends are NOT the same, and the old test pinned the
    // wrong one for both. In the Web Speech API `stop()` is the call that hands over the audio
    // the engine is still holding; `abort()` is the one that throws it away.
    context('ending the session', () => {
      it('keeps the last phrase when the mic is tapped again', () => {
        mic().click()
        engine().then(speech => speech.say('primera'))
        mic().click()

        engine().should(speech => {
          expect(speech.stopped, 'tapping the mic must not discard the audio').to.equal(1)
          expect(speech.aborted).to.equal(0)
        })
        // What `stop()` delivers afterwards still belongs to the person who said it.
        engine().then(speech => {
          speech.say('primera y la última frase')
          speech.emit('end')
        })

        field().should('have.value', 'primera y la última frase')
        mic().should('have.attr', 'aria-pressed', 'false')
      })

      it('throws the last phrase away when the person typed over it', () => {
        mic().click()
        engine().then(speech => speech.say('dictado'))
        field().type(' corregido')

        engine().should(speech => expect(speech.aborted).to.equal(1))
        // Anything still in the engine would rebuild the field from `base` and eat the
        // correction, so after an abort it is ignored.
        engine().then(speech => speech.say('dictado de más'))
        field().should('have.value', 'dictado corregido')
      })
    })

    context('when it fails', () => {
      it('puts the mic back for an error that may not happen again', () => {
        mic().click()
        engine().then(speech => speech.emit('error', { error: 'no-speech' }))

        mic().should('be.visible').and('have.attr', 'aria-pressed', 'false')
        status().should('not.be.visible')
      })

      // #1451 review. The mic is NOT retired: `not-allowed` is also what Chrome reports when the
      // permission prompt is dismissed without choosing, and `network` can be one bad second —
      // taking the button away for either would need a reload to undo. The line says what
      // happened, and the one control that can retry stays.
      it('says what happened and keeps the mic for another try', () => {
        mic().click()
        engine().then(speech => speech.emit('error', { error: 'not-allowed' }))

        status().should('be.visible').and('have.attr', 'role', 'status')
        mic().should('be.visible').and('have.attr', 'aria-pressed', 'false')

        mic().click()
        status().should('not.be.visible')
      })
    })
  })

  // The composer is the one control that starts with dictation on, so what is pinned here is
  // that it needs no wiring at the call site — and that `dictation: false` really is silent.
  context('in the chat composer', () => {
    const composer = () => cy.get('#composer-field')

    beforeEach(() => {
      cy.visit('/bali/chat/composer', {
        onBeforeLoad (win) {
          win.SpeechRecognition = function () {
            const listeners = {}
            const self = {
              lang: null,
              stopped: 0,
              aborted: 0,
              addEventListener (name, handler) { (listeners[name] ||= []).push(handler) },
              start () {},
              stop () { self.stopped += 1 },
              abort () { self.aborted += 1 },
              emit (name, event) { (listeners[name] || []).forEach(handler => handler(event)) },
              say (...phrases) {
                self.emit('result', { results: phrases.map(phrase => [{ transcript: phrase }]) })
              }
            }
            win.__speech = self
            return self
          }
          delete win.webkitSpeechRecognition
        }
      })
    })

    it('comes with a working mic and nothing to wire', () => {
      cy.get('#composer-form [data-speech-input-target="button"]').click()
      cy.window().then(win => win.__speech.say('dictado en el chat'))

      composer().should('have.value', 'dictado en el chat')
    })

    it('stops when the composer form is submitted, without leaving the page', () => {
      cy.get('#composer-form').then($form => {
        $form[0].addEventListener('submit', event => event.preventDefault())
      })
      cy.get('#composer-form [data-speech-input-target="button"]').click()
      cy.get('#composer-form button[type="submit"]').click()

      cy.window().should(win => expect(win.__speech.aborted).to.equal(1))
      cy.location('pathname').should('eq', '/lookbook/preview/bali/chat/composer')
    })

    it('renders no mic at all with `dictation: false`', () => {
      cy.get('#composer-field-mute')
        .parents('.bali-chat-composer')
        .find('[data-speech-input-target]')
        .should('not.exist')
    })
  })

  context('where the browser has none', () => {
    it('leaves the field exactly as it was', () => {
      visitWith({ recognition: false })

      mic().should('not.be.visible')
      status().should('not.be.visible')
      field().type('se teclea igual').should('have.value', 'se teclea igual')
    })
  })
})
