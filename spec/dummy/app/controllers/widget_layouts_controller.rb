# frozen_string_literal: true

# The ~15 lines a real host writes. Bali ships no controller and no routes: who
# may see which widget is the host's rule, so the host builds the `offering:` and
# its own store (`DashboardWidget::Store` here) can only ever subset it.
#
# Here the offering is the preview's own specimens and there is no signed-in
# user, so this exists to make the grid's PATCH succeed — which is what the
# Cypress spec asserts against.
class WidgetLayoutsController < ApplicationController
  # Dummy-only, and NOT because the layout lacks a token — `lookbook_preview.html.erb`
  # does call `csrf_meta_tags`, and the tag renders. The problem is one layer down:
  # rendering a preview never WRITES to the session, so Rails sends no session
  # cookie, and a token with no session behind it cannot be verified. Measured:
  # with this line removed, a PATCH carrying the page's own token still fails
  # `ActionController::InvalidAuthenticityToken`.
  #
  # A real host serves the grid from its own pages, inside a real session, and
  # keeps CSRF protection on — see docs/guides/engine-models.md for the example
  # worth copying. This file is scaffolding that makes the preview's fetch
  # succeed; it is deliberately NOT the reference implementation.
  skip_forgery_protection

  def update
    head :no_content
  end
end
