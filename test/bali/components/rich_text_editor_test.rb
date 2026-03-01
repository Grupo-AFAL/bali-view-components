# frozen_string_literal: true

require "test_helper"

class BaliRichTextEditorComponentTest < ComponentTestCase
  def setup
    @options = {}
    @original_enabled = Bali.rich_text_editor_enabled
    Bali.rich_text_editor_enabled = true
  end

  def teardown
    Bali.rich_text_editor_enabled = @original_enabled
  end

  def test_renders_richtexteditor_component
    render_inline(Bali::RichTextEditor::Component.new(**@options))
    assert_selector("div.rich-text-editor-component")
  end
end
