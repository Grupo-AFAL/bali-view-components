# frozen_string_literal: true

require "test_helper"

# `Bali::RichTextEditor::Component#render?` returns `Bali.rich_text_editor_enabled`, which the
# package ships as `false`. With the flag off the component emits NOTHING —not even the `<div>` its
# template opens— so the preview answered 200 with an empty body and read exactly like a broken
# component (#844). The defect was not the flag: it was that the preview did not say so.
class RichTextEditorPreviewTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[default readonly].freeze

  def setup
    @original = Bali.rich_text_editor_enabled
  end

  def teardown
    Bali.rich_text_editor_enabled = @original
  end

  def test_with_the_flag_off_the_preview_explains_itself_instead_of_rendering_nothing
    Bali.rich_text_editor_enabled = false

    PREVIEWS.each do |scenario|
      get "/lookbook/preview/bali/rich_text_editor/#{scenario}"

      assert_response :ok
      assert_select ".alert-component", { minimum: 2 },
        "#{scenario} no explica por qué está vacío"
      assert_select ".rich-text-editor-component", false,
        "#{scenario} dice que el componente está apagado y aun así lo renderiza"
    end
  end

  # The other half: the explanation has to disappear the moment the host turns the flag on, or the
  # preview starts lying in the opposite direction.
  def test_with_the_flag_on_the_preview_renders_the_component
    Bali.rich_text_editor_enabled = true

    PREVIEWS.each do |scenario|
      get "/lookbook/preview/bali/rich_text_editor/#{scenario}"

      assert_response :ok
      assert_select ".rich-text-editor-component", { minimum: 1 },
        "#{scenario} no renderizó el editor con el flag encendido"
      assert_select ".alert-component", false,
        "#{scenario} sigue avisando que está apagado con el flag encendido"
    end
  end

  # The disabled preview points at BlockEditor, which is the documented migration. If that path
  # stops existing the notice sends the reader to a 404 just as it is asking them to migrate.
  def test_the_disabled_notice_links_to_a_block_editor_preview_that_exists
    Bali.rich_text_editor_enabled = false

    get "/lookbook/preview/bali/rich_text_editor/default"
    href = css_select("a[href*='block_editor']").first&.[]("href")
    assert href, "el aviso no ofrece la alternativa"

    get href.sub("/lookbook/inspect/", "/lookbook/preview/")
    assert_response :ok, "el link a BlockEditor del aviso apunta a un preview que no renderiza"
  end
end
