# frozen_string_literal: true

require "test_helper"

# `?locale=` reaches every Lookbook preview and its layout, the way a host's locale reaches
# its pages: Bali's translations and `<html lang>`, which the confirm dialog reads.
class PreviewLocaleTest < ActionDispatch::IntegrationTest
  PREVIEW = "/lookbook/preview/bali/drawer/dirty_form"

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
