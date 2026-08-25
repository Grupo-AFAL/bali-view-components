# frozen_string_literal: true

# The ~15 lines a real host writes. Bali ships no controller and no routes: who
# may see which widget is the host's rule, so the host builds the `offering:` and
# `Bali::Widget::Layout` can only ever subset it.
#
# Here the offering is the preview's own specimens and there is no signed-in
# user, so this exists to make the grid's PATCH succeed — which is what the
# Cypress spec asserts against.
class WidgetLayoutsController < ApplicationController
  # Dummy-only: the grid is exercised from a Lookbook preview, and Lookbook's
  # preview layout does not emit `csrf_meta_tags` — so `request.js` has no token
  # to send. A real host serves the grid from its own pages and keeps CSRF
  # protection on. See spec/dummy/app/controllers/admin/projects/schedules_controller.rb
  # for the same pattern.
  skip_forgery_protection

  def update
    head :no_content
  end
end
