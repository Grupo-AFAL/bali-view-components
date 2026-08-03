# frozen_string_literal: true

require "test_helper"

# `Bali::RichTextEditor::Component#render?` devuelve `Bali.rich_text_editor_enabled`, que el
# paquete trae en `false`. Con el flag apagado el componente no emite NADA —ni el `<div>` que
# abre su template— así que el preview contestaba 200 con el body vacío y se leía igual que un
# componente roto (#844). El defecto no era el flag: era que el preview no lo decía.
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

  # La otra mitad: la explicación tiene que desaparecer en cuanto el host enciende el flag, o
  # el preview pasa a mentir en la dirección contraria.
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

  # El preview apagado apunta a BlockEditor, que es la migración documentada. Si esa ruta deja
  # de existir el aviso manda al lector a un 404 justo cuando le está pidiendo que migre.
  def test_the_disabled_notice_links_to_a_block_editor_preview_that_exists
    Bali.rich_text_editor_enabled = false

    get "/lookbook/preview/bali/rich_text_editor/default"
    href = css_select("a[href*='block_editor']").first&.[]("href")
    assert href, "el aviso no ofrece la alternativa"

    get href.sub("/lookbook/inspect/", "/lookbook/preview/")
    assert_response :ok, "el link a BlockEditor del aviso apunta a un preview que no renderiza"
  end
end
