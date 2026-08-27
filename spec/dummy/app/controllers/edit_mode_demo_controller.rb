# frozen_string_literal: true

# Two independent `edit-mode` regions on one page.
#
# Scaffolding for `cypress/e2e/edit-mode.cy.js`. The controller remembers its
# mode in a query param, and that param is configurable precisely so two regions
# can coexist — a hardcoded `editing` would have them entering and leaving
# together. Nothing else in the dummy app puts two on a page, so nothing else
# could catch that.
class EditModeDemoController < ApplicationController
  def index; end
end
