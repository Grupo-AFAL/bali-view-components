# frozen_string_literal: true

require "test_helper"

class BaliDocumentEditorComponentTest < ComponentTestCase
  def test_renders_overlay_container
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-controller='document-editor']")
    assert_selector(".document-editor-overlay")
  end

  def test_renders_app_bar_with_title
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector(".document-editor-app-bar")
    assert_selector("input[value='My Document']")
  end

  def test_renders_close_button
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      close_url: "/documents/1"
    ))
    assert_selector("a[href='/documents/1']")
  end

  def test_renders_toc_toggle
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-action*='document-editor#toggleToc']")
  end

  def test_renders_comments_toggle_when_comments_configured
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { comments: { url: "/block_editor_comments", user: { id: "1", username: "demo" } } }
    ))
    assert_selector("[data-action*='document-editor#toggleComments']")
  end

  def test_no_comments_toggle_without_config
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-action*='document-editor#toggleComments']")
  end

  def test_renders_history_toggle_when_versions_url_present
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      versions_url: "/documents/1/versions"
    ))
    assert_selector("[data-action*='document-editor#toggleHistory']")
  end

  def test_no_history_toggle_without_versions_url
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-action*='document-editor#toggleHistory']")
  end

  def test_renders_in_readonly_mode
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      editable: false
    ))
    assert_selector(".document-editor-overlay")
    assert_no_selector("input[data-document-editor-target='titleInput']")
  end

  def test_renders_editable_title_input
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      editable: true
    ))
    assert_selector("input[data-document-editor-target='titleInput']")
  end

  def test_renders_auto_save_values
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      auto_save: true,
      auto_save_delay: 5000
    ))
    assert_selector("[data-document-editor-auto-save-value='true']")
    assert_selector("[data-document-editor-auto-save-delay-value='5000']")
  end

  def test_defaults_close_url_to_document_url
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("a[href='/documents/1'][data-action='document-editor#close']")
  end

  def test_renders_editor_content_area
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector(".document-editor-overlay .flex-1.overflow-y-auto")
  end

  def test_renders_comments_panel_when_configured
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { comments: { url: "/comments", user: { id: "1", username: "demo" } } }
    ))
    assert_selector("[data-document-editor-target='commentsPanel']")
    assert_text("Comments")
  end

  def test_no_comments_panel_without_config
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-document-editor-target='commentsPanel']")
  end

  def test_renders_history_panel_when_versions_url_present
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      versions_url: "/documents/1/versions"
    ))
    assert_selector("[data-document-editor-target='historyPanel']")
    assert_text("Version History")
  end

  def test_no_history_panel_without_versions_url
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-document-editor-target='historyPanel']")
  end

  def test_renders_readonly_title_as_heading
    render_inline(Bali::DocumentEditor::Component.new(
      title: "Read Only Doc",
      initial_content: [],
      document_url: "/documents/1",
      editable: false
    ))
    assert_selector("h1", text: "Read Only Doc")
  end

  def test_renders_export_dropdown_when_export_enabled
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: true }
    ))
    assert_selector("[data-action='document-editor#exportPdf']")
    assert_selector("[data-action='document-editor#exportDocx']")
  end

  def test_no_export_dropdown_when_export_disabled
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: false }
    ))
    assert_no_selector("[data-action='document-editor#exportPdf']")
  end

  def test_renders_toc_panel_with_portal_container
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-target='tocPanel']")
    assert_selector("[id^='document-editor-toc-']")
  end

  def test_passes_custom_input_name_to_controller
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      input_name: "article[body]"
    ))
    assert_selector("[data-document-editor-input-name-value='article[body]']")
  end

  def test_defaults_input_name_to_document_content
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-input-name-value='document[content]']")
  end

  def test_accepts_custom_classes_via_options
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      class: "custom-editor"
    ))
    assert_selector(".document-editor-overlay.custom-editor")
  end

  def test_accepts_data_attributes_via_options
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      id: "my-editor"
    ))
    assert_selector("#my-editor.document-editor-overlay")
  end

  # --- REST contract (#700) ---------------------------------------------------

  # The controller used to POST to "#{document_url}/restore_version", a path it
  # invented. It is now a declared value with the same default, so an app whose
  # routes already matched keeps working while one that does not can say so.
  def test_restore_version_url_defaults_to_the_conventional_path
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-restore-version-url-value='/documents/1/restore_version']")
  end

  def test_restore_version_url_can_be_named_by_the_host
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      restore_version_url: "/documents/1/revisions/restore"
    ))
    assert_selector("[data-document-editor-restore-version-url-value='/documents/1/revisions/restore']")
  end

  # --- `:auto`, the mounted engine's endpoints (#707) -------------------------

  # `:auto` points both URLs at Bali::ContentVersionsController, which needs the record
  # named in the query string because its routes are not nested under the host's.
  def test_auto_urls_resolve_to_the_mounted_engine_for_the_given_record
    document = Document.create!(title: "Acta", author_name: "Ana")

    render_inline(Bali::DocumentEditor::Component.new(
      title: "Acta",
      initial_content: [],
      document_url: "/documents/#{document.id}",
      versions_url: :auto,
      restore_version_url: :auto,
      record: document
    ))

    assert_selector("[data-document-editor-versions-url-value='" \
                    "/bali/content_versions?record_id=#{document.id}&record_type=Document']")
    assert_selector("[data-document-editor-restore-version-url-value='" \
                    "/bali/content_versions/restore?record_id=#{document.id}&record_type=Document']")
  end

  # Without a record there is nothing to name, so the panel stays off instead of
  # rendering one whose every request would 404.
  def test_auto_without_a_record_leaves_the_history_panel_off
    render_inline(Bali::DocumentEditor::Component.new(
      title: "Acta",
      initial_content: [],
      document_url: "/documents/1",
      versions_url: :auto
    ))

    assert_no_selector("[data-action*='document-editor#toggleHistory']")
    assert_selector("[data-document-editor-versions-url-value='']")
  end

  # The PATCH payload root and the hidden input name both used to hardcode
  # "document", which assumed every host named its model Document.
  def test_param_key_defaults_to_document_and_drives_the_input_name
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-param-key-value='document']")
    assert_selector("[data-document-editor-input-name-value='document[content]']")
  end

  def test_param_key_renames_the_payload_root_and_the_input_name
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/articles/1",
      param_key: :article
    ))
    assert_selector("[data-document-editor-param-key-value='article']")
    assert_selector("[data-document-editor-input-name-value='article[content]']")
  end

  def test_an_explicit_input_name_still_wins_over_the_derived_one
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/articles/1",
      param_key: :article,
      input_name: "article[body]"
    ))
    assert_selector("[data-document-editor-input-name-value='article[body]']")
  end

  # --- Shared config package (#700) -------------------------------------------

  def test_config_reaches_the_nested_block_editor
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { ai_url: "/ai", mentions_url: "/users" }
    ))
    assert_selector("[data-block-editor-ai-url-value='/ai']")
    assert_selector("[data-block-editor-mentions-url-value='/users']")
  end

  def test_config_accepts_a_config_object_as_well_as_a_hash
    config = Bali::BlockEditor::Config.new(ai_url: "/ai")
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: config
    ))
    assert_selector("[data-block-editor-ai-url-value='/ai']")
  end

  def test_export_filename_falls_back_to_the_parameterized_title
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Big Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: true }
    ))
    assert_selector("[data-block-editor-export-filename-value='my-big-document']")
  end

  def test_an_export_filename_in_the_config_beats_the_title
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Big Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: true, export_filename: "roadmap" }
    ))
    assert_selector("[data-block-editor-export-filename-value='roadmap']")
  end

  def test_the_save_status_strings_travel_as_values
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-status-unsaved-value='Unsaved changes']")
    assert_selector("[data-document-editor-status-saving-value='Saving...']")
    assert_selector("[data-document-editor-status-failed-value='Save failed']")
  end

  # The placeholders belong to the browser: it is the only side that knows the
  # clock time and the version number, so they have to survive Rails untouched.
  def test_the_two_status_values_with_runtime_data_keep_their_placeholder
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-status-saved-value='Saved at %{time}']")
    assert_selector("[data-document-editor-version-label-value='Version %{number}']")
  end

  def test_the_save_status_strings_follow_the_locale
    I18n.with_locale(:es) do
      render_inline(Bali::DocumentEditor::Component.new(
        title: "My Document",
        initial_content: [],
        document_url: "/documents/1"
      ))
    end
    assert_selector("[data-document-editor-status-unsaved-value='Cambios sin guardar']")
    assert_selector("[data-document-editor-status-saved-value='Guardado a las %{time}']")
    assert_selector("[data-document-editor-locale-value='es']")
  end

  # Intl.RelativeTimeFormat replaced four hardcoded English strings, and it needs
  # the locale to do it.
  def test_the_locale_reaches_the_controller
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-locale-value='en']")
  end

  # Both list messages are rendered up front and hidden; the controller only
  # picks which one to reveal, so it never has to build translated text.
  def test_renders_both_version_list_messages_hidden
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      versions_url: "/documents/1/versions"
    ))
    assert_selector("[data-document-editor-target='versionsError'].hidden",
                    text: "Failed to load versions.", visible: :all)
    assert_selector("[data-document-editor-target='versionsEmpty'].hidden",
                    text: "No versions yet.", visible: :all)
  end

  def test_the_version_list_messages_follow_the_locale
    I18n.with_locale(:es) do
      render_inline(Bali::DocumentEditor::Component.new(
        title: "My Document",
        initial_content: [],
        document_url: "/documents/1",
        versions_url: "/documents/1/versions"
      ))
    end
    assert_selector("[data-document-editor-target='versionsError']",
                    text: "No se pudieron cargar las versiones.", visible: :all)
    assert_selector("[data-document-editor-target='versionsEmpty']",
                    text: "Todavía no hay versiones.", visible: :all)
  end

  # Restoring goes through Bali's styled dialog now, which reads its labels off
  # the button -- the same channel DeleteLink uses. The button is cloned out of a
  # <template>, whose contents are inert, so the assertions read the raw markup.
  def test_the_restore_button_carries_translated_confirm_dialog_labels
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      versions_url: "/documents/1/versions"
    ))
    assert_includes rendered_content, 'data-bali-confirm-title="Restore version"'
    assert_includes rendered_content, 'data-bali-confirm-accept="Restore"'
    assert_includes rendered_content, 'data-bali-confirm-cancel="Cancel"'
    assert_selector("[data-document-editor-restore-confirm-value]")
  end

  def test_the_confirm_dialog_labels_follow_the_locale
    I18n.with_locale(:es) do
      render_inline(Bali::DocumentEditor::Component.new(
        title: "My Document",
        initial_content: [],
        document_url: "/documents/1",
        versions_url: "/documents/1/versions"
      ))
    end
    assert_includes rendered_content, 'data-bali-confirm-title="Restaurar versión"'
    assert_includes rendered_content, 'data-bali-confirm-cancel="Cancelar"'
  end
end
