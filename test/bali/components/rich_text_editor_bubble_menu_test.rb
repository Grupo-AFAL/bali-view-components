# frozen_string_literal: true

require "test_helper"

# La barra flotante del RichTextEditor no tenía test propio (#1028). Tras el
# fix de #1032 (los <a> sin href pasaron a <button>), esto congela el contrato
# a11y: cada control icon-only es un botón real con nombre accesible — también
# los tres triggers de dropdown (enlace, imagen, tabla), que #1032 no cubrió.
class BaliRichTextEditorBubbleMenuTest < ComponentTestCase
  def test_every_formatting_control_is_a_real_button_with_an_accessible_name
    render_inline(Bali::RichTextEditor::BubbleMenu::Component.new)

    %w[bold italic underline strikethrough].each do |mark|
      assert_selector("button[type='button'][aria-label='#{action_label(mark)}']")
    end
    %w[align_left align_center align_right].each do |align|
      assert_selector("button[type='button'][aria-label='#{action_label(align)}']")
    end
    assert_selector("input[type='color'][aria-label='#{action_label('text_color')}']")

    # El antipatrón que #1032 vino a matar no puede volver: todo control del
    # editor que dispara una acción es un <button>, nunca un <a> sin href.
    # (Los items de dropdown pasan por `tag: :button` en este mismo cambio.)
    assert_no_selector("a:not([href])[data-action*='rich-text-editor#']")
  end

  def test_the_dropdown_triggers_carry_an_accessible_name
    render_inline(Bali::RichTextEditor::BubbleMenu::Component.new(images_url: "/images"))

    %w[link image table].each do |trigger|
      assert_selector("[aria-label='#{action_label(trigger)}']")
    end
  end

  def test_the_image_panel_only_renders_with_an_images_url
    render_inline(Bali::RichTextEditor::BubbleMenu::Component.new)

    assert_no_selector("[aria-label='#{action_label('image')}']")
  end

  private

  def action_label(key)
    I18n.t("bali_view.rich_text_editor.bubble_menu.actions.#{key}")
  end
end
