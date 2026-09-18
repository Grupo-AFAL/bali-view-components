# frozen_string_literal: true

require "test_helper"

# `header_with_badge` and `header_complete` rendered the wrapper with
# `justify-between` — so the slot was set — and nothing inside it: inside a
# preview method `render` is `ViewComponent::Preview#render`, not the view's, so
# `header.with_badge { render Bali::Tag::Component.new(...) }` dropped the tag
# on the floor. Both previews exist to demonstrate that slot, and no component
# test or Cypress spec visits them, so the lie was invisible (#1148). They
# render a template now, like every Card preview that works.
#
# The scenarios of this file sit inside `@!group Headers`, so the URL that
# serves them is the group's — the per-scenario path 404s.
class CardHeaderPreviewsTest < ActionDispatch::IntegrationTest
  GROUP = "/lookbook/preview/bali/card/headers"

  def test_the_badge_previews_render_the_badge_they_advertise
    get GROUP
    assert_response :ok

    assert_select ".badge.tag-component", { text: "NEW", count: 1 },
      "header_with_badge renders the header without its badge"
    assert_select ".badge.tag-component", { text: "Beta", count: 1 },
      "header_complete renders the header without its badge"
    assert_select ".flex.items-center.gap-3.justify-between", { minimum: 2 },
      "the badge layout is gone from the header wrappers"
  end

  # The preview this PR added. A coloured icon over an uncoloured title is the
  # whole point of `icon_class:`, and nothing else renders it.
  def test_the_coloured_icon_preview_paints_the_icon_and_not_the_title
    get GROUP
    assert_response :ok

    assert_select "span.icon-component.text-warning", { count: 1 }
    assert_select "h2.card-title.text-warning", false, "the title must keep the neutral colour"
  end
end
