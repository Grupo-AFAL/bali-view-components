# frozen_string_literal: true

module Bali
  module Chat
    class Preview < ApplicationViewComponentPreview
      # @label Conversation
      # A live conversation: bubbles, a typing indicator and a composer.
      #
      # The container follows new messages only when you are already at the bottom.
      # Scroll up into the history, press **Send**, and the scrollbar stays where you
      # left it — press it again from the bottom and the view follows.
      #
      # **Send** and **Stop typing** stand in for what a real app does from the
      # server. In production the indicator is usually toggled by a Turbo Stream:
      #
      # ```erb
      # <%= turbo_stream.replace 'chat-typing-indicator' do %>
      #   <%= render Bali::Chat::TypingIndicator::Component.new(visible: true) %>
      # <% end %>
      # ```
      #
      # @param threshold number "Pixels short of the bottom that still count as 'at the bottom'"
      def default(threshold: 64)
        render_with_template(
          template: "bali/chat/previews/default",
          locals: { threshold: threshold.to_i }
        )
      end

      # @label Bubbles
      # Every shape a bubble takes. `position:` picks the side, `color:` the daisyUI
      # bubble colour, and the `avatar`, `header` and `footer` slots fill daisyUI's
      # `chat` grid around it.
      #
      # The body is rendered exactly as the host passes it — no escaping, no
      # sanitising. Markdown from a language model is the host's to render and clean
      # before it gets here.
      def bubbles
        render_with_template(template: "bali/chat/previews/bubbles")
      end

      # @label Typing indicator
      # Three animated dots in the shape of an incoming message. It stays in the DOM
      # and hides behind a class, so a Turbo Stream can replace it as often as it
      # likes without ever losing the anchor it targets.
      #
      # The label is read by screen readers whether or not it is drawn — dots alone
      # announce nothing.
      #
      # @param show_label toggle "Draw the label next to the dots"
      def typing_indicator(show_label: false)
        render_with_template(
          template: "bali/chat/previews/typing_indicator",
          locals: { show_label: show_label }
        )
      end
    end
  end
end
