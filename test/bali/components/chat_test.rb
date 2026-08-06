# frozen_string_literal: true

require "test_helper"

class BaliChatComponentTest < ComponentTestCase
  def test_renders_the_container_with_the_stimulus_controller
    render_inline(Bali::Chat::Component.new)
    assert_selector(".bali-chat[data-controller='chat']")
  end

  def test_messages_region_carries_the_stream_target_id_and_the_scroll_action
    render_inline(Bali::Chat::Component.new(id: "conversation_messages"))
    assert_selector("#conversation_messages[data-chat-target='messages']")
    assert_selector("#conversation_messages[data-action='scroll->chat#trackPosition']")
  end

  def test_messages_region_scrolls_and_can_shrink_inside_the_flex_column
    render_inline(Bali::Chat::Component.new)
    assert_selector("[data-chat-target='messages'].overflow-y-auto.flex-1.min-h-0")
  end

  def test_default_threshold_value
    render_inline(Bali::Chat::Component.new)
    assert_selector("[data-chat-threshold-value='64']")
  end

  def test_custom_threshold_value
    render_inline(Bali::Chat::Component.new(threshold: 120))
    assert_selector("[data-chat-threshold-value='120']")
  end

  def test_host_classes_land_on_the_wrapper_not_on_the_scroll_region
    render_inline(Bali::Chat::Component.new(class: "h-[60vh]"))
    assert_selector(".bali-chat.h-\\[60vh\\]")
    refute_selector("[data-chat-target='messages'].h-\\[60vh\\]")
  end

  def test_messages_class_extends_the_scroll_region
    render_inline(Bali::Chat::Component.new(messages_class: "gap-3 p-5"))
    assert_selector("[data-chat-target='messages'].gap-3.p-5")
  end

  def test_renders_content_inside_the_scroll_region
    render_inline(Bali::Chat::Component.new) { "conversation".html_safe }
    assert_selector("[data-chat-target='messages']", text: "conversation")
  end

  def test_footer_slot_renders_outside_the_scroll_region
    render_inline(Bali::Chat::Component.new) do |chat|
      chat.with_footer { "<form></form>".html_safe }
    end
    assert_selector(".bali-chat > .border-t form")
    refute_selector("[data-chat-target='messages'] form")
  end

  def test_no_footer_wrapper_without_the_slot
    render_inline(Bali::Chat::Component.new)
    refute_selector(".border-t")
  end
end

class BaliChatMessageComponentTest < ComponentTestCase
  def test_defaults_to_the_incoming_side_with_daisyui_default_bubble
    render_inline(Bali::Chat::Message::Component.new) { "Hi".html_safe }
    assert_selector(".chat.chat-start .chat-bubble", text: "Hi")
    refute_selector("[class*='chat-bubble-']")
  end

  def test_end_position
    render_inline(Bali::Chat::Message::Component.new(position: :end)) { "Hi".html_safe }
    assert_selector(".chat.chat-end")
  end

  def test_unknown_position_falls_back_to_start
    render_inline(Bali::Chat::Message::Component.new(position: :middle)) { "Hi".html_safe }
    assert_selector(".chat.chat-start")
  end

  def test_every_daisyui_bubble_colour_is_spelled_out
    Bali::Chat::Message::Component::COLORS.each do |color, class_name|
      render_inline(Bali::Chat::Message::Component.new(color: color)) { "Hi".html_safe }
      assert_selector(".chat-bubble.#{class_name}")
    end
  end

  def test_bubble_class_extends_the_bubble
    render_inline(Bali::Chat::Message::Component.new(bubble_class: "prose max-w-none")) do
      "Hi".html_safe
    end
    assert_selector(".chat-bubble.prose.max-w-none")
  end

  def test_author_and_timestamp_render_a_header
    at = Time.utc(2026, 8, 6, 15, 30)
    render_inline(Bali::Chat::Message::Component.new(author: "Ada", timestamp: at)) do
      "Hi".html_safe
    end
    assert_selector(".chat-header", text: "Ada")
    assert_selector(".chat-header time[datetime='#{at.iso8601}']")
  end

  def test_string_timestamp_is_printed_as_given_without_a_datetime_attribute
    render_inline(Bali::Chat::Message::Component.new(timestamp: "just now")) { "Hi".html_safe }
    assert_selector(".chat-header time", text: "just now")
    refute_selector("time[datetime]")
  end

  def test_no_header_without_author_or_timestamp
    render_inline(Bali::Chat::Message::Component.new) { "Hi".html_safe }
    refute_selector(".chat-header")
  end

  def test_header_slot_replaces_the_author_and_timestamp_pair
    render_inline(Bali::Chat::Message::Component.new(author: "Ada")) do |message|
      message.with_header { "Ada · edited".html_safe }
      "Hi".html_safe
    end
    assert_selector(".chat-header", text: "Ada · edited")
    refute_selector(".chat-header time")
  end

  # Guards the `before_render` that forces the block to run: the avatar is emitted
  # before the bubble, so a lazily evaluated slot would be silently dropped.
  def test_avatar_slot_renders_in_the_chat_image_cell
    render_inline(Bali::Chat::Message::Component.new) do |message|
      message.with_avatar { '<span class="avatar">AL</span>'.html_safe }
      "Hi".html_safe
    end
    assert_selector(".chat-image .avatar")
    assert_selector(".chat-bubble", text: "Hi")
  end

  def test_footer_slot_renders_in_the_chat_footer_cell
    render_inline(Bali::Chat::Message::Component.new) do |message|
      message.with_footer { "2 sources".html_safe }
      "Hi".html_safe
    end
    assert_selector(".chat-footer", text: "2 sources")
  end

  # The body belongs to the host: both source apps hand it Markdown they rendered
  # and sanitised themselves, so the component must neither escape nor unescape it.
  def test_html_content_passes_through_untouched
    render_inline(Bali::Chat::Message::Component.new) do
      "<p><strong>bold</strong></p>".html_safe
    end
    assert_selector(".chat-bubble p strong", text: "bold")
  end

  def test_html_options_reach_the_root_element
    render_inline(Bali::Chat::Message::Component.new(id: "message_7", class: "mt-2")) do
      "Hi".html_safe
    end
    assert_selector("#message_7.chat.mt-2")
  end
end

class BaliChatTypingIndicatorComponentTest < ComponentTestCase
  def test_lives_in_the_dom_hidden_by_a_class
    render_inline(Bali::Chat::TypingIndicator::Component.new)
    assert_selector("#chat-typing-indicator.bali-chat-typing.hidden")
  end

  def test_visible_drops_the_hidden_class
    render_inline(Bali::Chat::TypingIndicator::Component.new(visible: true))
    assert_selector("#chat-typing-indicator.bali-chat-typing")
    refute_selector(".bali-chat-typing.hidden")
  end

  def test_registers_itself_as_a_chat_target_so_the_container_can_toggle_it
    render_inline(Bali::Chat::TypingIndicator::Component.new)
    assert_selector("[data-chat-target='typing']")
  end

  def test_custom_id_for_a_second_chat_on_the_page
    render_inline(Bali::Chat::TypingIndicator::Component.new(id: "support-typing"))
    assert_selector("#support-typing")
  end

  def test_renders_a_message_bubble_with_daisyui_dots
    render_inline(Bali::Chat::TypingIndicator::Component.new)
    assert_selector(".chat.chat-start .chat-bubble .loading.loading-dots")
  end

  def test_announces_itself_to_assistive_technology
    render_inline(Bali::Chat::TypingIndicator::Component.new)
    assert_selector("[role='status'][aria-live='polite']")
    assert_selector(".sr-only", text: "Typing…")
  end

  def test_show_label_draws_the_label_instead_of_hiding_it
    render_inline(Bali::Chat::TypingIndicator::Component.new(show_label: true,
                                                            label: "The agent is typing"))
    assert_text("The agent is typing")
    refute_selector(".sr-only")
  end

  def test_label_default_resolves_through_the_locale_files
    I18n.with_locale(:es) do
      render_inline(Bali::Chat::TypingIndicator::Component.new)
    end
    assert_selector(".sr-only", text: "Escribiendo…")
  end

  def test_forwards_position_colour_and_author_to_the_bubble
    render_inline(Bali::Chat::TypingIndicator::Component.new(position: :end, color: :primary,
                                                            author: "Assistant"))
    assert_selector(".chat.chat-end .chat-bubble.chat-bubble-primary")
    assert_selector(".chat-header", text: "Assistant")
  end

  def test_avatar_slot_is_forwarded_to_the_bubble
    render_inline(Bali::Chat::TypingIndicator::Component.new) do |indicator|
      indicator.with_avatar { '<span class="avatar">AI</span>'.html_safe }
    end
    assert_selector(".chat-image .avatar")
    assert_selector(".loading-dots")
  end
end
