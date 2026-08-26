# frozen_string_literal: true

# Scaffolding for `cypress/e2e/modal-history.cy.js`, which verifies what the Back
# button does after `ModalController#_replaceBodyAndURL` swaps the document.
#
# That path runs only when a modal trigger's fetch is REDIRECTED — the modal
# gives up on rendering a panel and turns into a navigation instead, replacing
# `document.body` and pushing the destination's URL. Nothing else in the dummy
# app reaches it, which is why its history behaviour went unverified while the
# widget grid's equivalent was measured; see the note in
# `docs/superpowers/specs/2026-08-25-widgets-and-widget-grid-design.md`.
class ModalRedirectController < ApplicationController
  def index; end

  # The trigger points here. This bounces, which is what makes `response.redirected`
  # true on the modal's `fetch` and sends it down the body-swapping branch.
  def go
    redirect_to modal_redirect_landing_path
  end

  def landing; end
end
