# frozen_string_literal: true

require "test_helper"

# The component tests render classes, not previews, and Cypress only visits
# `/bali/chat/default`. Everything specific to the preview path — the nested
# `Bali::Chat::Message` / `Bali::Chat::TypingIndicator` constants resolving under a
# namespace Zeitwerk reloads, `render_with_template` finding three templates in a
# directory the engine excludes from eager loading — could 500 with the suite green.
class ChatPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    "/lookbook/preview/bali/chat/default" => "[data-controller='chat'] [data-chat-target='messages']",
    "/lookbook/preview/bali/chat/bubbles" => ".chat.chat-end .chat-bubble-primary",
    "/lookbook/preview/bali/chat/typing_indicator" => ".loading-dots"
  }.freeze

  def test_every_chat_preview_renders_with_its_marker_element
    PREVIEWS.each do |path, marker|
      get path
      assert_response :ok, "#{path} did not render"
      assert_select marker, { minimum: 1 }, "#{path} rendered without #{marker}"
    end
  end

  # The whole point of the toggle-by-class design: the node a Turbo Stream targets is
  # served on the page from the first render, hidden, so it is still there to target
  # after any number of replaces.
  def test_the_typing_indicator_ships_hidden_inside_the_conversation
    get "/lookbook/preview/bali/chat/default"

    assert_select "#chat-typing-indicator.hidden[data-chat-target='typing']", 1
  end
end
