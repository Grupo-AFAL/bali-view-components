# frozen_string_literal: true

require "test_helper"

# The `compact` preview is where #1148 is demonstrated and where
# cypress/e2e/reveal-spacing.cy.js takes its measurements, so its ids and the
# host classes written on them are a contract, not decoration. Component tests
# render classes, not previews, so without this a rename here would only show
# up as a Cypress failure — or not at all, if Cypress is skipped.
class RevealPreviewsTest < ActionDispatch::IntegrationTest
  def test_the_compact_preview_renders_the_cases_it_is_measured_on
    get "/lookbook/preview/bali/reveal/compact"
    assert_response :ok

    assert_select "#reveal-default .reveal-trigger", { count: 1 }
    assert_select "#reveal-compact .reveal-trigger.pb-2.mb-2", { count: 1 }
    assert_select "#reveal-compact-second .reveal-trigger.pb-0.mb-0", { count: 1 }
    assert_select "#reveal-icon-tight .trigger-icon.h-2", { count: 1 }

    assert_select "#reveal-default .reveal-trigger.pb-6", false,
      "the default spacing belongs to reveal/index.css, not to the markup"
  end

  def test_every_reveal_preview_still_renders
    %w[default external_controls compact with_icon_and_title].each do |scenario|
      get "/lookbook/preview/bali/reveal/#{scenario}"
      assert_response :ok, "/lookbook/preview/bali/reveal/#{scenario} did not render"
    end
  end
end
