# frozen_string_literal: true

require "test_helper"

# #1092 — las tres superficies del editor terminan en `**options`, que se rendean como
# atributos del div raíz. Una kwarg que el componente no declara no levantaba error, no
# advertía, producía HTML válido y dejaba la característica en su valor por omisión: en una
# app anfitriona, IA, export, referencias y comentarios llevaban apagados desde la migración
# a v3, y dos pantallas "de solo lectura" eran editables y aceptaban subidas.
class BaliBlockEditorSilentKwargsTest < ComponentTestCase
  def setup
    @original_enabled = Bali.block_editor_enabled
    Bali.block_editor_enabled = true
  end

  def teardown
    Bali.block_editor_enabled = @original_enabled
  end

  # readonly:

  def test_readonly_turns_editing_off_instead_of_painting_an_attribute
    component = Bali.deprecator.silence { Bali::BlockEditor::Component.new(readonly: true) }

    assert_not component.editable?
  end

  def test_readonly_false_is_editable
    component = Bali.deprecator.silence { Bali::BlockEditor::Component.new(readonly: false) }

    assert component.editable?
  end

  def test_readonly_warns_and_names_the_spelling_that_replaces_it
    warning = capture_warning { Bali::BlockEditor::Component.new(readonly: true) }

    assert_match "readonly:", warning
    assert_match "editable: false", warning
  end

  def test_document_editor_takes_readonly_too
    warning = capture_warning do
      component = Bali::DocumentEditor::Component.new(
        title: "Doc", initial_content: [], document_url: "/d/1", readonly: true
      )
      assert_not component.editable?
    end

    assert_match "editable: false", warning
  end

  def test_not_passing_readonly_leaves_editable_alone_and_warns_nothing
    warning = capture_warning { assert Bali::BlockEditor::Component.new.editable? }

    assert_empty warning
  end

  # Config keys passed loose

  def test_a_config_key_passed_loose_warns_and_names_config
    warning = capture_warning do
      Bali::DocumentEditor::Component.new(
        title: "Doc", initial_content: [], document_url: "/d/1", ai_url: "/ai"
      )
    end

    assert_match "`ai_url:`", warning
    assert_match "config:", warning
  end

  def test_every_loose_config_key_is_named_at_once
    warning = capture_warning do
      Bali::DocumentEditor::Component.new(
        title: "Doc", initial_content: [], document_url: "/d/1",
        ai_url: "/ai", export: true, comments: { url: "/c" }
      )
    end

    assert_match "`ai_url:`", warning
    assert_match "`export:`", warning
    assert_match "`comments:`", warning
  end

  # Los tres `references_*` de DocumentPage son los que dejaban los chips de la ficha
  # publicada con el ícono y la etiqueta por omisión.
  def test_document_page_warns_about_its_references_keys
    warning = capture_warning do
      Bali::DocumentPage::Component.new(title: "Doc", initial_content: [],
                                        references_url: "/refs")
    end

    assert_match "`references_url:`", warning
  end

  def test_a_key_inside_config_warns_nothing
    warning = capture_warning do
      Bali::DocumentEditor::Component.new(
        title: "Doc", initial_content: [], document_url: "/d/1", config: { ai_url: "/ai" }
      )
    end

    assert_empty warning
  end

  # `data:` y `class:` SÍ tienen que seguir llegando al elemento: el aviso es sobre las
  # llaves de Config, no sobre todo lo que caiga en `**options`.
  def test_an_ordinary_html_option_still_reaches_the_element
    warning = capture_warning do
      render_inline(Bali::BlockEditor::Component.new(id: "editor-1", data: { role: "editor" }))
    end

    assert_empty warning
    assert_selector "#editor-1.block-editor-component[data-role='editor']"
  end

  # editable: false => uploads off

  # No pasar `upload_url:` no apaga las subidas: las enciende, porque su default es `:auto`
  # y eso resuelve al endpoint del engine. Un visor no tiene por qué llevarlo.
  def test_a_viewer_does_not_get_the_engine_upload_endpoint
    render_inline(Bali::BlockEditor::Component.new(editable: false))

    assert_no_selector "[data-block-editor-upload-url-value]", visible: :all
  end

  def test_an_editor_does_get_it
    render_inline(Bali::BlockEditor::Component.new(editable: true))

    assert_selector "[data-block-editor-upload-url-value]", visible: :all
  end

  # La mitad que faltaba: `:auto` ya miraba `editable?`, una url explícita no.
  def test_an_explicit_upload_url_is_dropped_on_a_viewer_too
    component = Bali::BlockEditor::Component.new(editable: false, upload_url: "/uploads")

    assert_nil component.upload_url
  end

  def test_an_explicit_upload_url_survives_on_an_editor
    component = Bali::BlockEditor::Component.new(editable: true, upload_url: "/uploads")

    assert_equal "/uploads", component.upload_url
  end

  private

  def capture_warning
    captured = []
    Bali.deprecator.behavior = ->(message, *) { captured << message }
    yield
    captured.join("\n")
  ensure
    Bali.deprecator.behavior = :stderr
  end
end
