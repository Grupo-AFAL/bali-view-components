# frozen_string_literal: true

require "test_helper"

# Every layout of the dummy declares the request's locale as `<html lang>`, as the fleet's
# layouts do: it is what the confirm dialog's buttons and a hand-written SlimSelect read.
class HtmlLangTest < ActionDispatch::IntegrationTest
  PREVIEW = "/lookbook/preview/bali/drawer/dirty_form"

  # One page per layout: application, admin, auth, marketing and app_layout_preview.
  PAGES = %w[/showcase /workspace /login /landing /sidemenu-example].freeze

  def test_every_dummy_layout_declares_the_locale_asked_for
    PAGES.each do |path|
      get path, params: { locale: "es" }

      assert_response :success, path
      assert_select "html[lang=es]", { count: 1 }, "#{path} does not declare lang=es"
    end
  end

  # `?locale=` reaches a Lookbook preview and its layout: Bali's translations as well as
  # `<html lang>`.
  def test_a_preview_renders_in_the_locale_asked_for
    get PREVIEW, params: { locale: "es" }

    assert_response :success
    assert_select "html[lang=es]"
    assert_select "[data-drawer-confirm-close-message-value=?]",
                  I18n.t("bali_view.drawer.confirm_close", locale: :es)
  end

  def test_a_preview_renders_in_the_default_locale_otherwise
    get PREVIEW

    assert_response :success
    assert_select "html[lang=en]"
  end
end
