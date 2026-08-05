# frozen_string_literal: true

require "test_helper"

class BaliDocumentPageComponentTest < ComponentTestCase
  def test_renders_with_title
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_body { "Document content preview" }
    end
    assert_text("My Document")
    assert_text("Document content preview")
  end

  def test_renders_breadcrumbs
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      breadcrumbs: [
        { name: "Dashboard", href: "/" },
        { name: "Documents", href: "/documents" },
        { name: "My Document" }
      ]
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector(".breadcrumbs")
  end

  def test_renders_actions
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_action { "Edit Button" }
      page.with_body { "Content" }
    end
    assert_text("Edit Button")
  end

  def test_secondary_actions_alone_still_paint_the_actions_bar
    # El gate era `if actions?`, así que una página con SOLO acciones secundarias no pintaba
    # ni el ⋯ ni el divisor que lo separa de los toggles de paneles.
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_secondary_action(name: "Export", href: "/documents/1.pdf")
      page.with_body { "Content" }
    end

    assert_selector('[aria-label="More actions"]', visible: :all)
    # Regla propia y no `.divider.divider-horizontal` de daisyUI: esa clase traía un
    # `width: 1rem` propio que se sumaba al gap de la fila (#846).
    assert_selector(".w-0\\.5.h-6.bg-base-content\\/10", visible: :all)
  end

  def test_renders_subtitle
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      subtitle: "Last edited 2 hours ago"
    )) do |page|
      page.with_body { "Content" }
    end
    assert_text("Last edited 2 hours ago")
  end

  def test_renders_back_button
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      back: { href: "/documents" }
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector("a[href='/documents']")
  end

  def test_renders_title_tags
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_title_tag { "Draft" }
      page.with_body { "Content" }
    end
    assert_text("Draft")
  end

  def test_renders_stimulus_controller
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_body { "Content" }
    end
    assert_selector("[data-controller='document-page']")
  end

  def test_renders_three_panel_layout_with_metadata
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Metadata content" }
      page.with_body { "Preview content" }
    end
    assert_text("Metadata content")
    assert_text("Preview content")
    assert_selector("[data-document-page-target='metadataPanel']")
    assert_selector("[data-action='document-page#toggleMetadata']")
  end

  def test_renders_metadata_toggle_in_header
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Metadata" }
      page.with_body { "Content" }
    end
    assert_selector("[data-document-page-target='metadataToggle']")
  end

  def test_no_toggles_without_panels
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_body { "Content" }
    end
    assert_no_selector("[data-action='document-page#toggleToc']")
    assert_no_selector("[data-action='document-page#toggleMetadata']")
  end

  def test_renders_simple_layout_without_metadata
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_body { "Just preview" }
    end
    assert_text("Just preview")
    assert_no_selector("[data-document-page-target='metadataPanel']")
  end

  def test_accepts_custom_classes_via_options
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      class: "custom-page"
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector(".document-page-component.custom-page")
  end

  def test_accepts_data_attributes_via_options
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      id: "my-page"
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector("#my-page.document-page-component")
  end

  def test_toc_panel_defaults_open
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ].to_json
    )) do |page|
      page.with_metadata { "Meta" }
    end
    assert_selector("[data-document-page-toc-open-value='true']")
  end

  def test_toc_panel_can_default_closed
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ].to_json,
      toc_open: false
    )) do |page|
      page.with_metadata { "Meta" }
    end
    assert_selector("[data-document-page-toc-open-value='false']")
  end

  def test_metadata_panel_defaults_open
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Meta" }
      page.with_body { "Content" }
    end
    assert_selector("[data-document-page-metadata-open-value='true']")
  end

  def test_metadata_panel_can_default_closed
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      metadata_open: false
    )) do |page|
      page.with_metadata { "Meta" }
      page.with_body { "Content" }
    end
    assert_selector("[data-document-page-metadata-open-value='false']")
  end

  def test_renders_toc_panel_with_block_editor_content
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ].to_json
    )) do |page|
      page.with_metadata { "Meta" }
    end
    assert_selector("[data-document-page-target='tocPanel']")
    assert_selector("#document-page-toc-container")
    assert_selector("[data-action='document-page#toggleToc']")
  end

  def test_no_toc_without_initial_content
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Meta" }
      page.with_body { "Content" }
    end
    assert_no_selector("[data-document-page-target='tocPanel']")
    assert_no_selector("[data-action='document-page#toggleToc']")
  end

  # Las tres cadenas de los paneles salen de `bali_view.document_page.*` y no del template.
  # Se movieron al componente al unificar el encabezado, así que el `t('.x')` relativo ahora
  # se resuelve desde la clase: si el scope se rompiera, esto vería "translation missing".
  def test_the_panel_labels_come_from_i18n
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [] } ].to_json
    )) { |page| page.with_metadata { "Meta" } }

    html = page.native.to_html
    refute_includes html, "translation missing"
    assert_includes html, I18n.t("bali_view.document_page.toggle_toc")
    assert_includes html, I18n.t("bali_view.document_page.toggle_details")
    assert_includes html, I18n.t("bali_view.document_page.contents")
  end

  def test_falls_back_to_content_slot_without_body_or_initial_content
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) { "Fallback content" }
    assert_text("Fallback content")
  end

  # El slot se llamaba `preview` y ahora se llama `body`, como en los otros cuatro. El shim
  # avisa y sigue pintando: un host que no lo renombre no se queda con la página en blanco.
  def test_the_preview_slot_still_renders_and_warns
    message = nil
    Bali.deprecator.behavior = ->(warning, *) { message = warning }

    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_preview { "Legacy preview content" }
    end

    assert_text("Legacy preview content")
    assert_match(/`preview` slot of Bali::DocumentPage is deprecated/, message)
  ensure
    Bali.deprecator.behavior = :stderr
  end

  def test_three_panel_container_stacks_on_mobile
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Meta" }
      page.with_body { "Content" }
    end
    assert_selector(".flex.items-start.max-lg\\:flex-col")
  end

  def test_toc_panel_has_mobile_stacking_classes
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ].to_json
    )) do |page|
      page.with_metadata { "Meta" }
    end
    assert_selector(
      "[data-document-page-target='tocPanel'].max-lg\\:w-full.max-lg\\:static.max-lg\\:max-h-72" \
        ".max-lg\\:border-r-0.max-lg\\:border-b"
    )
  end

  def test_metadata_panel_has_mobile_stacking_classes
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Meta" }
      page.with_body { "Content" }
    end
    assert_selector(
      "[data-document-page-target='metadataPanel'].max-lg\\:w-full.max-lg\\:static" \
        ".max-lg\\:max-h-none.max-lg\\:border-l-0.max-lg\\:border-t"
    )
  end

  def test_toolbar_wraps_on_mobile
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_action { "Edit Button" }
      page.with_body { "Content" }
    end
    assert_selector(".flex.items-center.gap-2.flex-wrap")
  end
end
