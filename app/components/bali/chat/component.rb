# frozen_string_literal: true

module Bali
  module Chat
    # Scrollable conversation container — the Turbo Stream append target plus the
    # autoscroll that makes a live conversation readable.
    #
    # Extracted from two hand-rolled chats (afal-apps' TDFlow interview and
    # gobierno-corporativo's document assistant). Both force-scroll to the bottom
    # on every DOM mutation, which yanks a reader who scrolled up into the history
    # back down the moment an answer lands. This container follows the conversation
    # only when the reader was already at the bottom; `threshold:` says how close
    # that has to be.
    #
    # The height is the host's to decide. The wrapper is a flex column with no size
    # of its own, so pass `class: 'h-[60vh]'` (or a max-height, or let a flex parent
    # size it) and the message region takes what is left.
    #
    #   <%= render Bali::Chat::Component.new(id: 'messages', class: 'h-[60vh]') do |chat| %>
    #     <% chat.with_header do %><%= render 'chat_header' %><% end %>
    #     <%= render Bali::Chat::Message::Component.new(position: :end, color: :primary) do %>
    #       Hello
    #     <% end %>
    #     <%= render Bali::Chat::TypingIndicator::Component.new(class: 'order-last') %>
    #     <% chat.with_footer do %><%= render 'form' %><% end %>
    #   <% end %>
    #
    # and from the controller or the job that answers:
    #
    #   turbo_stream.append 'messages', partial: 'messages/message', locals: { message: }
    class Component < ApplicationViewComponent
      renders_one :header
      # The escape hatch, and what the two source apps still use: a footer of the host's own
      # REPLACES the composer. One of them stacks a coverage banner, an actions turbo-frame and
      # a rate-limit hint around its row; a container that imposed a composer would break it.
      renders_one :footer
      # Buttons that belong in the composer's row, between the field and send — an attach, a
      # model picker. Ignored when the host brought its own footer.
      renders_many :composer_actions

      # @param id [String] DOM id of the scrollable message region — the target a
      #   Turbo Stream appends into (`turbo_stream.append 'chat-messages'`). Give
      #   each chat on a page its own id.
      # @param threshold [Integer] How many pixels short of the bottom still count
      #   as "at the bottom" when deciding whether to follow a new message.
      #   Sub-pixel layout rounding means an exact 0 rarely holds, so the default
      #   carries a little slack rather than a fudge factor.
      # @param messages_class [String, nil] Extra classes for the scrollable region.
      #   Padding and the gap between messages live here: the two implementations
      #   this came from disagreed (`p-4`/`space-y-4` against `p-5`/`gap-3`), so the
      #   default is one of them and the other passes a string.
      # @param url [String, nil] Where a message is posted. THIS is what brings the composer:
      #   give the chat a url and it renders the form, the field, the mic and send, so adding a
      #   chat to a screen is one component and not three. Leave it out for a read-only
      #   transcript, and the chat stays what it was.
      # @param composer [Hash] Options forwarded to `Chat::Composer::Component` — `name:`,
      #   `placeholder:`, `submit:`, `rows:`, `dictation:`, `field_options:`, `submit_options:`.
      #   Dictation is on unless `dictation: false` says otherwise.
      # @param form_options [Hash] Onto the `form_with` the composer sits in: a `method:`, a
      #   `data:` of the host's own.
      def initialize(id: "chat-messages", threshold: 64, messages_class: nil,
                     url: nil, composer: {}, form_options: {}, **options)
        @id = id
        @threshold = threshold
        @messages_class = messages_class
        @url = url
        @composer = composer
        @form_options = form_options
        @options = options
      end

      private

      attr_reader :id, :threshold, :messages_class, :url, :composer, :form_options, :options

      # The host's footer wins: it is the whole footer, and a composer under it would be a
      # second one.
      def own_composer? = url.present? && !footer?

      def composer_component
        Bali::Chat::Composer::Component.new(**{ name: "message[content]" }.merge(composer))
      end

      def composer_form_options = { url: url }.merge(form_options)

      def wrapper_attributes
        attrs = prepend_controller(options.dup, "chat")
        attrs = prepend_values(attrs, "chat", threshold: threshold)
        prepend_class_name(attrs, "bali-chat flex flex-col min-h-0")
      end

      def messages_classes
        class_names("flex-1 min-h-0 overflow-y-auto flex flex-col gap-4 p-4", messages_class)
      end
    end
  end
end
