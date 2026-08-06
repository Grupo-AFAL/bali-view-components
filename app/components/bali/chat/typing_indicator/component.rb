# frozen_string_literal: true

module Bali
  module Chat
    module TypingIndicator
      # The "…is typing" bubble: three animated dots in the shape of an incoming
      # message, so the wait reads as part of the conversation.
      #
      # It stays in the DOM and hides behind a class, which is the repo's pattern and
      # also the fix for a bug both source implementations have. One clones the
      # indicator from a `<template>` and deletes it again from a MutationObserver;
      # the other renders a bare `<div id="typing-indicator"></div>` as a Turbo Stream
      # anchor and then `broadcast_remove_to`s it — which destroys the anchor, so
      # every later `turbo_stream.replace` silently does nothing and the indicator
      # never comes back. A node that is never removed cannot lose its anchor.
      #
      # Show and hide it either from the server:
      #
      #   turbo_stream.replace 'chat-typing-indicator' do
      #     render Bali::Chat::TypingIndicator::Component.new(visible: true)
      #   end
      #
      # or from the page, through the container's controller — the indicator
      # registers itself as a `chat` target:
      #
      #   data: { action: 'turbo:submit-end->chat#showTyping' }
      #
      # The dots are daisyUI's `loading loading-dots`, so this component ships no CSS.
      class Component < ApplicationViewComponent
        renders_one :avatar

        # @param id [String] DOM id, and the Turbo Stream target. One per chat.
        # @param visible [Boolean] Whether it starts shown. Hidden is the common
        #   case: render it once at the end of the conversation and toggle it.
        # @param position [Symbol] `:start` or `:end` — see
        #   {Bali::Chat::Message::Component}. Defaults to the incoming side.
        # @param color [Symbol, nil] daisyUI bubble colour, to match the messages it
        #   stands in for.
        # @param author [String, nil] Name above the bubble, for symmetry with the
        #   answer that replaces it.
        # @param label [String, nil] What the indicator announces. Read by screen
        #   readers whether or not it is drawn, since three dots say nothing.
        # @param show_label [Boolean] Also draw the label next to the dots.
        # @param bubble_class [String, nil] Extra classes for the bubble.
        def initialize(id: "chat-typing-indicator", visible: false, position: :start,
                       color: nil, author: nil, label: nil, show_label: false,
                       bubble_class: nil, **options)
          @id = id
          @visible = visible
          @position = position
          @color = color
          @author = author
          @label = label.presence || I18n.t("bali_view.chat.typing_indicator.label")
          @show_label = show_label
          @bubble_class = bubble_class
          @options = options
        end

        # See {Bali::Chat::Message::Component#before_render}: the avatar slot is
        # forwarded, so it has to be set before it is asked about.
        def before_render
          content
        end

        private

        attr_reader :id, :visible, :position, :color, :author, :label, :show_label,
                    :bubble_class, :options

        def wrapper_attributes
          attrs = options.dup
          attrs[:id] = id
          attrs[:role] = "status"
          attrs[:aria] = { live: "polite" }.merge(attrs[:aria] || {})
          attrs = prepend_data_attribute(attrs, :chat_target, "typing")
          prepend_class_name(attrs, class_names("bali-chat-typing", "hidden" => !visible))
        end
      end
    end
  end
end
