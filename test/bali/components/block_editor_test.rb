# frozen_string_literal: true

require "test_helper"

class BaliBlockEditorComponentTest < ComponentTestCase
  def setup
    @original_enabled = Bali.block_editor_enabled
    Bali.block_editor_enabled = true
  end

  def teardown
    Bali.block_editor_enabled = @original_enabled
  end

  # #1091 — el formato de persistencia pasa a ser del host y deja de depender de si alguien
  # dejó un comentario.
  def test_format_accepts_the_two_pinned_json_shapes
    %i[blocks prosemirror].each do |format|
      render_inline(Bali::BlockEditor::Component.new(format: format, input_name: "doc[content]"))

      assert_selector("[data-block-editor-format-value='#{format}']", visible: :all)
    end
  end

  def test_format_rejects_an_unknown_value_instead_of_serializing_json_in_silence
    error = assert_raises(ArgumentError) do
      Bali::BlockEditor::Component.new(format: :prose)
    end

    assert_match "unknown format", error.message
    assert_match "prosemirror", error.message
  end

  # El input declara en qué forma está su valor, para que el host no la adivine por la
  # estructura. Lo pone el servidor y lo mantiene al día `useContentSync`.
  def test_the_hidden_input_declares_the_shape_of_the_stored_content
    render_inline(Bali::BlockEditor::Component.new(
                    input_name: "doc[content]",
                    initial_content: [ { "id" => "1", "type" => "paragraph" } ]
                  ))

    assert_selector("input[data-content-format='blocks']", visible: :all)
  end

  def test_the_hidden_input_declares_prosemirror_content_as_such
    render_inline(Bali::BlockEditor::Component.new(
                    input_name: "doc[content]",
                    initial_content: { "type" => "doc", "content" => [] }
                  ))

    assert_selector("input[data-content-format='prosemirror']", visible: :all)
  end

  def test_the_hidden_input_declares_a_non_json_format_as_itself
    render_inline(Bali::BlockEditor::Component.new(
                    input_name: "doc[content]", format: :markdown, markdown_content: "# Hola"
                  ))

    assert_selector("input[data-content-format='markdown']", visible: :all)
  end

  def test_renders_block_editor_component
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector("div.block-editor-component")
  end

  def test_does_not_render_when_block_editor_enabled_is_false
    Bali.block_editor_enabled = false
    render_inline(Bali::BlockEditor::Component.new)
    assert_no_selector("div.block-editor-component")
  end

  def test_renders_editor_target_container
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-target="editor"]')
  end

  def test_renders_hidden_input_when_input_name_is_provided
    render_inline(Bali::BlockEditor::Component.new(input_name: "post[content]"))
    assert_selector('input[type="hidden"][name="post[content]"]', visible: false)
  end

  def test_does_not_render_hidden_input_when_input_name_is_nil
    render_inline(Bali::BlockEditor::Component.new)
    assert_no_selector('input[type="hidden"][data-block-editor-target="output"]')
  end

  def test_applies_editable_data_value
    render_inline(Bali::BlockEditor::Component.new(editable: true))
    assert_selector('[data-block-editor-editable-value="true"]')
  end

  def test_applies_non_editable_data_value
    render_inline(Bali::BlockEditor::Component.new(editable: false))
    assert_selector('[data-block-editor-editable-value="false"]')
  end

  def test_does_not_render_hidden_input_when_not_editable
    render_inline(Bali::BlockEditor::Component.new(editable: false, input_name: "post[content]"))
    assert_no_selector('input[type="hidden"]', visible: false)
  end

  def test_applies_placeholder_data_value
    render_inline(Bali::BlockEditor::Component.new(placeholder: "Write here..."))
    assert_selector('[data-block-editor-placeholder-value="Write here..."]')
  end

  def test_serializes_hash_content_to_json
    blocks = [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ]
    render_inline(Bali::BlockEditor::Component.new(initial_content: blocks, input_name: "post[content]"))
    input = page.find('input[type="hidden"]', visible: false)
    assert_equal(blocks.to_json, input.value)
  end

  def test_passes_string_content_directly
    json_str = '[{"type":"paragraph"}]'
    render_inline(Bali::BlockEditor::Component.new(initial_content: json_str, input_name: "post[content]"))
    input = page.find('input[type="hidden"]', visible: false)
    assert_equal(json_str, input.value)
  end

  def test_applies_format_data_value
    render_inline(Bali::BlockEditor::Component.new(format: :html))
    assert_selector('[data-block-editor-format-value="html"]')
  end

  def test_applies_custom_css_classes
    render_inline(Bali::BlockEditor::Component.new(class: "custom-class"))
    assert_selector("div.block-editor-component.custom-class")
  end

  def test_defaults_to_the_medium_text_size
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector("div.block-editor-component.block-editor-size-md")
  end

  def test_applies_the_requested_text_size_class
    render_inline(Bali::BlockEditor::Component.new(size: :sm))
    assert_selector("div.block-editor-component.block-editor-size-sm")
  end

  def test_accepts_a_string_text_size
    render_inline(Bali::BlockEditor::Component.new(size: "lg"))
    assert_selector("div.block-editor-component.block-editor-size-lg")
  end

  def test_treats_a_nil_text_size_as_the_default
    render_inline(Bali::BlockEditor::Component.new(size: nil))
    assert_selector("div.block-editor-component.block-editor-size-md")
  end

  def test_keeps_custom_classes_alongside_the_text_size
    render_inline(Bali::BlockEditor::Component.new(size: :xs, class: "custom-class"))
    assert_selector("div.block-editor-component.block-editor-size-xs.custom-class")
  end

  # An Integer is what `size:` means on the input families (the HTML
  # attribute), and it can now arrive here through `block_editor_group`
  # (#1076) — the rejection must be the clear ArgumentError, not a
  # NoMethodError out of `4.to_sym`.
  def test_a_size_that_cannot_name_a_scale_raises_with_the_valid_names
    error = assert_raises(ArgumentError) do
      Bali::BlockEditor::Component.new(size: 4)
    end
    assert_match(/unknown size 4/, error.message)
    assert_match(/:xs/, error.message)
  end

  # The size must never reach the wrapper as an HTML attribute: every keyword the
  # component does not name is forwarded onto the div, and `size="sm"` on a div is
  # a silent no-op that looks like it worked.
  def test_does_not_leak_the_text_size_as_an_html_attribute
    render_inline(Bali::BlockEditor::Component.new(size: :sm))
    assert_no_selector("div.block-editor-component[size]", visible: :all)
  end

  def test_raises_on_an_unknown_text_size
    error = assert_raises(ArgumentError) do
      render_inline(Bali::BlockEditor::Component.new(size: :huge))
    end

    assert_includes error.message, "unknown size :huge"
    assert_includes error.message, ":xs, :sm, :md, :lg"
  end

  def test_sets_controller_data_attribute
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-controller="block-editor"]')
  end

  def test_applies_upload_url_data_value_when_explicitly_set
    render_inline(Bali::BlockEditor::Component.new(upload_url: "/uploads"))
    assert_selector('[data-block-editor-upload-url-value="/uploads"]')
  end

  def test_applies_html_content_data_value
    render_inline(Bali::BlockEditor::Component.new(html_content: "<p>Hello</p>"))
    assert_selector("[data-block-editor-html-content-value]")
  end

  def test_with_auto_upload_url_resolves_from_bali_block_editor_upload_url_config
    original = Bali.block_editor_upload_url
    Bali.block_editor_upload_url = "/bali/block_editor/uploads"
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-upload-url-value="/bali/block_editor/uploads"]')
  ensure
    Bali.block_editor_upload_url = original
  end

  def test_with_auto_upload_url_does_not_set_upload_url_when_not_editable
    original = Bali.block_editor_upload_url
    Bali.block_editor_upload_url = "/bali/block_editor/uploads"
    render_inline(Bali::BlockEditor::Component.new(editable: false))
    assert_no_selector("[data-block-editor-upload-url-value]")
  ensure
    Bali.block_editor_upload_url = original
  end

  def test_with_auto_upload_url_does_not_set_upload_url_when_upload_url_is_nil
    render_inline(Bali::BlockEditor::Component.new(upload_url: nil))
    assert_no_selector("[data-block-editor-upload-url-value]")
  end

  def test_with_table_of_contents_sets_table_of_contents_value_to_false_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-table-of-contents-value="false"]')
  end

  def test_with_table_of_contents_sets_table_of_contents_value_to_true_when_enabled
    render_inline(Bali::BlockEditor::Component.new(table_of_contents: true))
    assert_selector('[data-block-editor-table-of-contents-value="true"]')
  end

  def test_with_comments_sets_comments_value_to_false_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-comments-value="false"]')
  end

  def test_with_comments_sets_comments_value_to_true_when_enabled
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" } }))
    assert_selector('[data-block-editor-comments-value="true"]')
  end

  def test_with_comments_serializes_comments_user_as_json
    user = { id: "1", username: "Alice", avatar_url: "" }
    render_inline(Bali::BlockEditor::Component.new(comments: { user: user }))
    assert_selector("[data-block-editor-comments-user-value]")
    el = page.find("[data-block-editor-comments-user-value]")
    parsed = JSON.parse(el[:"data-block-editor-comments-user-value"])
    assert_equal("1", parsed["id"])
    assert_equal("Alice", parsed["username"])
  end

  def test_with_comments_serializes_comments_users_as_json_array
    users = [
    { id: "1", username: "Alice" }, { id: "2", username: "Bob" }
    ]
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" }, users: users }))
    el = page.find("[data-block-editor-comments-users-value]")
    parsed = JSON.parse(el[:"data-block-editor-comments-users-value"])
    assert_kind_of(Array, parsed)
    assert_equal(2, parsed.length)
    assert_equal("Alice", parsed.first["username"])
  end

  def test_with_comments_applies_comments_users_url_data_value
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" }, users_url: "/api/users" }))
    assert_selector('[data-block-editor-comments-users-url-value="/api/users"]')
  end

  def test_with_comments_applies_comments_url_data_value_for_rest_persistence
    render_inline(Bali::BlockEditor::Component.new(comments: { url: "/block_editor_comments", user: { id: "1", username: "Alice" } }))
    assert_selector('[data-block-editor-comments-url-value="/block_editor_comments"]')
  end

  # #706 — `:auto` points the store at the engine's endpoints for one record. The
  # commentable travels in the query string, which is what scopes all nine of them:
  # RESTThreadStore._buildUrl keeps it on every sub-request.
  def test_with_comments_auto_url_resolves_the_engine_path_scoped_to_the_commentable
    document = Document.create!(title: "Contrato", author_name: "Ana", content: [])
    render_inline(Bali::BlockEditor::Component.new(
                    comments: { url: :auto, commentable: document, user: { id: "1", username: "Alice" } }
                  ))

    url = page.find("[data-block-editor-comments-url-value]")[:"data-block-editor-comments-url-value"]
    assert_equal "/bali/block_editor_comments?commentable_id=#{document.id}&commentable_type=Document", url
  end

  # Failing loudly beats an editor that silently reads someone else's threads, or none.
  def test_with_comments_auto_url_without_a_commentable_raises
    error = assert_raises(ArgumentError) do
      render_inline(Bali::BlockEditor::Component.new(comments: { url: :auto, user: { id: "1", username: "Alice" } }))
    end

    assert_match(/commentable/, error.message)
  end

  def test_with_comments_defaults_comments_url_to_empty_string
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" } }))
    assert_selector('[data-block-editor-comments-url-value=""]')
  end

  # `threads:` is what lets a store that does not persist open with something in it — the
  # comments sidebar reads the STORE, so a seeded thread lists without the document having
  # to say anything. Anchoring it is the other half, and travels in the ProseMirror form of
  # `initial_content` (#863).
  def test_with_comments_serializes_seed_threads_as_json_array
    threads = [
      { id: "t1", comments: [ { id: "c1", userId: "2", body: [ { type: "paragraph" } ] } ] }
    ]
    render_inline(Bali::BlockEditor::Component.new(
                    comments: { user: { id: "1", username: "Alice" }, threads: threads }
                  ))

    parsed = JSON.parse(page.find("[data-block-editor-comments-threads-value]")[:"data-block-editor-comments-threads-value"])
    assert_equal(1, parsed.size)
    assert_equal("t1", parsed.first["id"])
    assert_equal("c1", parsed.first["comments"].first["id"])
  end

  def test_with_comments_defaults_seed_threads_to_an_empty_array
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" } }))
    assert_selector('[data-block-editor-comments-threads-value="[]"]')
  end

  def test_export_functionality_does_not_render_export_buttons_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_no_selector('[data-action*="exportPdf"]')
    assert_no_selector('[data-action*="exportDocx"]')
  end

  def test_export_functionality_renders_both_export_buttons_when_export_true
    render_inline(Bali::BlockEditor::Component.new(export: true))
    assert_selector('button[data-action="block-editor#exportPdf"]')
    assert_selector('button[data-action="block-editor#exportDocx"]')
    assert_text("Export PDF")
    assert_text("Export DOCX")
  end

  def test_export_functionality_renders_only_pdf_button_when_export_pdf
    render_inline(Bali::BlockEditor::Component.new(export: [ :pdf ]))
    assert_selector('button[data-action="block-editor#exportPdf"]')
    assert_no_selector('[data-action*="exportDocx"]')
  end

  def test_export_functionality_renders_only_docx_button_when_export_docx
    render_inline(Bali::BlockEditor::Component.new(export: [ :docx ]))
    assert_no_selector('[data-action*="exportPdf"]')
    assert_selector('button[data-action="block-editor#exportDocx"]')
  end

  def test_export_functionality_applies_export_filename_data_value
    render_inline(Bali::BlockEditor::Component.new(export_filename: "my-report"))
    assert_selector('[data-block-editor-export-filename-value="my-report"]')
  end

  def test_export_functionality_defaults_export_filename_to_document
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-export-filename-value="document"]')
  end

  # --- Markdown storage, presets and quiet-failure guard ---

  def test_accepts_markdown_content_and_format
    render_inline(Bali::BlockEditor::Component.new(format: :markdown, markdown_content: "**hola**"))
    assert_selector('[data-block-editor-format-value="markdown"]')
    assert_selector('[data-block-editor-markdown-content-value="**hola**"]')
  end

  # The hidden input has to carry the original content: a form submitted before
  # the editor mounts would otherwise blank the column.
  def test_hidden_input_is_seeded_with_the_markdown_content
    render_inline(
      Bali::BlockEditor::Component.new(
        format: :markdown, markdown_content: "texto previo", input_name: "post[body]"
      )
    )
    assert_selector('input[name="post[body]"][value="texto previo"]', visible: false)
  end

  def test_hidden_input_is_seeded_with_the_html_content
    render_inline(
      Bali::BlockEditor::Component.new(
        format: :html, html_content: "<p>hola</p>", input_name: "post[body]"
      )
    )
    assert_selector('input[name="post[body]"][value="<p>hola</p>"]', visible: false)
  end

  def test_defaults_to_the_full_preset
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-preset-value="full"]')
  end

  def test_accepts_the_simple_preset
    render_inline(Bali::BlockEditor::Component.new(preset: :simple))
    assert_selector('[data-block-editor-preset-value="simple"]')
  end

  def test_syntax_highlighting_is_on_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-syntax-highlighting-value="true"]')
  end

  # Turning it off keeps `shiki` (~9 MB of grammars) out of the bundle.
  def test_syntax_highlighting_can_be_turned_off
    render_inline(Bali::BlockEditor::Component.new(syntax_highlighting: false))
    assert_selector('[data-block-editor-syntax-highlighting-value="false"]')
  end

  # Whether shiki is installed is an installation-level fact, so an app sets it
  # once in the initializer instead of at all 19 call sites.
  def test_syntax_highlighting_follows_the_global_configuration
    original = Bali.block_editor_syntax_highlighting
    Bali.block_editor_syntax_highlighting = false

    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-syntax-highlighting-value="false"]')
  ensure
    Bali.block_editor_syntax_highlighting = original
  end

  def test_an_explicit_value_overrides_the_global_configuration
    original = Bali.block_editor_syntax_highlighting
    Bali.block_editor_syntax_highlighting = false

    render_inline(Bali::BlockEditor::Component.new(syntax_highlighting: true))
    assert_selector('[data-block-editor-syntax-highlighting-value="true"]')
  ensure
    Bali.block_editor_syntax_highlighting = original
  end

  def test_locale_follows_the_application_by_default
    I18n.with_locale(:es) do
      render_inline(Bali::BlockEditor::Component.new)
      assert_selector('[data-block-editor-locale-value="es"]')
    end
  end

  def test_locale_can_be_set_explicitly
    render_inline(Bali::BlockEditor::Component.new(locale: :fr))
    assert_selector('[data-block-editor-locale-value="fr"]')
  end

  # Rendering an empty string when the flag is off is the single most common way
  # this component is mis-installed: no markup, no error, and a green test suite.
  def test_logs_a_warning_when_rendered_while_disabled
    Bali.block_editor_enabled = false
    output = StringIO.new
    original = Rails.logger
    Rails.logger = Logger.new(output)

    begin
      render_inline(Bali::BlockEditor::Component.new)
    ensure
      Rails.logger = original
    end

    assert_includes output.string, "block_editor_enabled"
  end

  # --- Shared config package (#700) -------------------------------------------

  def test_config_supplies_the_feature_set
    render_inline(Bali::BlockEditor::Component.new(config: { ai_url: "/ai", multi_column: true }))
    assert_selector("[data-block-editor-ai-url-value='/ai']")
    assert_selector("[data-block-editor-multi-column-value='true']")
  end

  # A host passes the bundle its app always uses, then turns one feature off for
  # one editor. Without the UNSET sentinel this was impossible: `ai_url: nil` and
  # "argument not given" were the same thing.
  def test_an_explicit_keyword_overrides_the_config
    render_inline(Bali::BlockEditor::Component.new(
      config: { ai_url: "/ai", multi_column: true },
      multi_column: false
    ))
    assert_selector("[data-block-editor-ai-url-value='/ai']")
    assert_selector("[data-block-editor-multi-column-value='false']")
  end

  def test_an_explicit_nil_can_switch_a_configured_feature_off
    render_inline(Bali::BlockEditor::Component.new(
      config: { ai_url: "/ai" },
      ai_url: nil
    ))
    assert_selector("[data-block-editor-ai-url-value='']")
  end

  def test_the_config_object_is_not_mutated_by_being_rendered
    config = Bali::BlockEditor::Config.new(ai_url: "/ai", multi_column: true)
    render_inline(Bali::BlockEditor::Component.new(config: config, multi_column: false))

    assert config.multi_column, "rendering must not write back into the caller's config"
  end

  def test_comments_poll_interval_is_unset_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector("[data-block-editor-comments-poll-interval-value='-1']")
  end

  # 0 is a real value -- it turns polling off -- so it must survive as itself
  # rather than being read as "not configured".
  def test_comments_poll_interval_of_zero_survives
    render_inline(Bali::BlockEditor::Component.new(
      config: { comments: { url: "/c", user: { id: "1" }, poll_interval: 0 } }
    ))
    assert_selector("[data-block-editor-comments-poll-interval-value='0']")
  end

  def test_comments_poll_interval_can_be_configured
    render_inline(Bali::BlockEditor::Component.new(
      config: { comments: { url: "/c", user: { id: "1" }, poll_interval: 30000 } }
    ))
    assert_selector("[data-block-editor-comments-poll-interval-value='30000']")
  end

  def test_every_string_the_react_bundle_renders_travels_as_one_json_value
    render_inline(Bali::BlockEditor::Component.new)

    assert_equal(
      %w[load_failed plain_text table_of_contents upload_failed upload_not_configured
         upload_too_large user_fallback],
      react_translations.keys.sort
    )
    assert_equal "Table of contents", react_translations["table_of_contents"]
  end

  def test_the_react_strings_follow_the_locale
    I18n.with_locale(:es) { render_inline(Bali::BlockEditor::Component.new) }

    assert_equal "Tabla de contenido", react_translations["table_of_contents"]
    assert_equal "La carga de archivos no está configurada", react_translations["upload_not_configured"]
    assert_equal "Texto plano", react_translations["plain_text"]
  end

  # The file size, the HTTP status and the unresolved user id only exist in the
  # browser, so these sentences have to reach it uninterpolated.
  def test_the_strings_with_runtime_data_keep_their_placeholders
    render_inline(Bali::BlockEditor::Component.new)

    assert_includes react_translations["upload_too_large"], "%{size}"
    assert_includes react_translations["upload_too_large"], "%{max}"
    assert_includes react_translations["upload_failed"], "%{status}"
    assert_includes react_translations["user_fallback"], "%{id}"
  end

  # references_config derivado del registry (#708)

  def test_the_registry_display_config_reaches_the_editor_without_declaring_it_again
    with_entity_reference_types do
      render_inline(Bali::BlockEditor::Component.new)

      assert_equal({ "icon" => "▧", "label" => "Documento", "color" => "success" },
                   react_references_config["Document"])
    end
  end

  def test_an_explicit_references_config_wins_over_the_registry
    with_entity_reference_types do
      render_inline(Bali::BlockEditor::Component.new(
                      references_config: { "Document" => { icon: "★", label: "Otro", color: "warning" } }
                    ))

      assert_equal "★", react_references_config.dig("Document", "icon")
    end
  end

  def test_a_type_without_display_stays_out_of_the_config
    with_entity_reference_types do
      render_inline(Bali::BlockEditor::Component.new)

      assert_not react_references_config.key?("Task"), "sin display: no hay nada que configurar"
    end
  end

  private

  def with_entity_reference_types
    original = Bali.entity_reference_types
    Bali.entity_reference_types = {
      "Document" => { search_scope: -> { Document.all }, lookup_scope: -> { Document.all },
                      search_fields: %i[title], display_field: :title,
                      display: { icon: "▧", label: "Documento", color: "success" } },
      "Task" => { search_scope: -> { Task.all }, lookup_scope: -> { Task.all },
                  search_fields: %i[title], display_field: :title }
    }
    yield
  ensure
    Bali.entity_reference_types = original
  end

  def react_references_config
    JSON.parse(page.find("[data-block-editor-references-config-value]", visible: :all)["data-block-editor-references-config-value"])
  end

  def react_translations
    JSON.parse(page.find("[data-block-editor-translations-value]", visible: :all)["data-block-editor-translations-value"])
  end

  # The inline sidebar renders inside `.block-editor-component`, so that is where
  # the flag the CSS reads has to be. See #1111 and `Config#comments_sidebar`.
  def test_the_threads_sidebar_flag_is_absent_when_it_is_interactive
    render_inline(Bali::BlockEditor::Component.new(config: { comments: { url: "/c" } }))

    assert_no_selector(".block-editor-component[data-comments-sidebar]")
  end

  def test_the_threads_sidebar_flag_lands_on_the_root_when_read_only_is_asked_for
    render_inline(
      Bali::BlockEditor::Component.new(config: { comments: { url: "/c", sidebar: :read_only } })
    )

    assert_selector(".block-editor-component[data-comments-sidebar='read-only']")
  end

  def test_an_unknown_sidebar_mode_raises_at_the_call_site
    assert_raises(ArgumentError) do
      Bali::BlockEditor::Component.new(config: { comments: { sidebar: :nope } })
    end
  end

  # The root flag only covers the sidebar that renders inside the root, and
  # `comments_container_id:` portals it out of there — into markup Rails does not
  # render the contents of. So the mode also travels as a Stimulus value, and the
  # React wrapper puts it on that container. Without it, `sidebar: :read_only` plus
  # `comments_container_id:` was a mode that silently did nothing (#1113).
  def test_the_sidebar_mode_travels_to_the_react_wrapper
    render_inline(
      Bali::BlockEditor::Component.new(
        config: { comments: { url: "/c", sidebar: :read_only } },
        comments_container_id: "host-panel"
      )
    )

    assert_selector("[data-block-editor-comments-sidebar-value='read-only']", visible: :all)
    assert_selector("[data-block-editor-comments-container-id-value='host-panel']", visible: :all)
  end

  # Both modes are written, so a host reading the value can tell "interactive" apart
  # from "this editor is too old to say".
  def test_the_interactive_mode_is_named_in_the_value_too
    render_inline(Bali::BlockEditor::Component.new(config: { comments: { url: "/c" } }))

    assert_selector("[data-block-editor-comments-sidebar-value='interactive']", visible: :all)
  end
end
