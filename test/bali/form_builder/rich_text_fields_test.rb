# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderRichTextFieldsTest < FormBuilderTestCase
  def setup
    super if defined?(super)
    @original_enabled = Bali.block_editor_enabled
    Bali.block_editor_enabled = true
  end

  def teardown
    Bali.block_editor_enabled = @original_enabled
    super if defined?(super)
  end

  # #rich_text_group

  def test_rich_text_group_renders_a_fieldset_wrapper
    result = builder.rich_text_group(:synopsis)
    assert_html(result, "fieldset.fieldset")
  end

  def test_rich_text_group_renders_a_legend_label
    result = builder.rich_text_group(:synopsis)
    assert_html(result, "legend.fieldset-legend", text: "Synopsis")
  end

  def test_rich_text_group_renders_the_block_editor_component
    result = builder.rich_text_group(:synopsis)
    assert_html(result, 'div.block-editor-component[data-controller="block-editor"]')
  end

  def test_rich_text_group_derives_the_input_name_from_the_object
    result = builder.rich_text_group(:synopsis)
    assert_html(result, 'input[type="hidden"][name="movie[synopsis]"]', visible: false)
  end

  def test_rich_text_group_defaults_to_the_simple_preset
    result = builder.rich_text_group(:synopsis)
    assert_html(result, '[data-block-editor-preset-value="simple"]')
  end

  def test_rich_text_group_defaults_to_markdown_storage
    result = builder.rich_text_group(:synopsis)
    assert_html(result, '[data-block-editor-format-value="markdown"]')
  end

  # Keeping every reader (search, exports, APIs, prompts) working depends on the
  # column staying Markdown, so the value has to reach the editor as Markdown.
  def test_rich_text_group_passes_the_current_value_as_markdown_content
    resource.synopsis = "**bold** and a list"
    result = builder.rich_text_group(:synopsis)
    assert_html(result, '[data-block-editor-markdown-content-value="**bold** and a list"]')
  end

  # If the user never touches the editor the form still posts the hidden input:
  # an empty one would silently blank the column.
  def test_rich_text_group_seeds_the_hidden_input_with_the_current_value
    resource.synopsis = "contenido previo"
    result = builder.rich_text_group(:synopsis)
    assert_html(result, 'input[value="contenido previo"]', visible: false)
  end

  # Field-group options are consumed by the wrapper; leaking them onto the
  # component turns them into bogus HTML attributes (label="...", help="...").
  def test_rich_text_group_does_not_leak_field_group_options_as_html_attributes
    result = builder.rich_text_group(:synopsis, label: "Sinopsis", help: "Una ayuda", required: true)
    refute_html(result, "div.block-editor-component[label]")
    refute_html(result, "div.block-editor-component[help]")
  end

  def test_rich_text_group_renders_the_help_text
    result = builder.rich_text_group(:synopsis, help: "Una ayuda")
    assert_html(result, "p.fieldset-label", text: "Una ayuda")
  end

  # #block_editor_group

  def test_block_editor_group_defaults_to_the_full_preset
    result = builder.block_editor_group(:synopsis)
    assert_html(result, '[data-block-editor-preset-value="full"]')
  end

  def test_block_editor_group_accepts_an_explicit_format
    result = builder.block_editor_group(:synopsis, format: :json)
    assert_html(result, '[data-block-editor-format-value="json"]')
  end

  def test_block_editor_group_passes_the_value_as_initial_content_for_json
    resource.synopsis = '[{"type":"paragraph"}]'
    result = builder.block_editor_group(:synopsis, format: :json)
    assert_includes result, 'data-block-editor-initial-content-value="[{&quot;type&quot;:&quot;paragraph&quot;}]"'
  end

  def test_block_editor_group_passes_the_value_as_html_content_for_html
    resource.synopsis = "<p>hola</p>"
    result = builder.block_editor_group(:synopsis, format: :html)
    assert_includes result, 'data-block-editor-html-content-value="&lt;p&gt;hola&lt;/p&gt;"'
  end

  def test_helpers_render_nothing_when_the_block_editor_is_disabled
    Bali.block_editor_enabled = false
    result = builder.rich_text_group(:synopsis)
    refute_html(result, "div.block-editor-component")
  end
end
