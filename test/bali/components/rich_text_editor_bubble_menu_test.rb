# frozen_string_literal: true

require "test_helper"

# The RichTextEditor's floating bar had no test of its own (#1028). After #1032's fix (the href-less
# <a>s became <button>s), this freezes the a11y contract: every icon-only control is a real button
# with an accessible name — including the three dropdown triggers (link, image, table), which #1032
# did not cover.
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

    # The antipattern #1032 came to kill cannot come back: every editor control that fires an action
    # is a <button>, never an href-less <a>. (The dropdown items go through `tag: :button` in this
    # same change.)
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
