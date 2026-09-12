# frozen_string_literal: true

module Bali
  module Chat
    module Message
      # One conversation bubble, over daisyUI's `chat` grid.
      #
      # Deliberately not "user vs assistant": both implementations this was
      # extracted from compute a side and a colour from their own role enum, and
      # they disagree on the colour (`chat-bubble-neutral` against a bordered
      # `bg-base-200`). What they share is the daisyUI vocabulary, so that is the
      # API — the host keeps its own role names and maps them here. A support chat
      # between two humans reads no worse for it than an AI one.
      #
      # The bubble body is whatever the host passes as content, unescaped and
      # unsanitised. Both sources render Markdown produced by a language model
      # through their own helper (Commonmarker with `unsafe: false` in one, Kramdown
      # plus Rails' `sanitize` in the other); which of those a host wants is not this
      # component's business, and a `raw` here would take the decision away.
      class Component < ApplicationViewComponent
        POSITIONS = {
          start: "chat-start",
          end: "chat-end"
        }.freeze

        # Spelled out rather than interpolated: Tailwind scans this file for class
        # names, and daisyUI only emits the rules it sees used. `"chat-bubble-#{color}"`
        # would compile to nothing.
        COLORS = {
          neutral: "chat-bubble-neutral",
          primary: "chat-bubble-primary",
          secondary: "chat-bubble-secondary",
          accent: "chat-bubble-accent",
          info: "chat-bubble-info",
          success: "chat-bubble-success",
          warning: "chat-bubble-warning",
          error: "chat-bubble-error"
        }.freeze

        renders_one :avatar
        renders_one :header
        renders_one :footer

        # @param position [Symbol] `:start` (left — the other party) or `:end`
        #   (right — the reader's own message). daisyUI's own names, and RTL-aware.
        # @param color [Symbol, nil] daisyUI bubble colour. `nil` leaves the default
        #   `base-300` bubble, which is what a neutral incoming message wants.
        # @param author [String, nil] Name above the bubble. Renders a `chat-header`.
        # @param timestamp [Time, Date, String, nil] Shown next to the author in a
        #   `<time>` with a machine-readable `datetime`. A String is printed as given.
        # @param timestamp_format [Symbol] `I18n.l` format for the timestamp.
        # @param bubble_class [String, nil] Extra classes for the bubble itself —
        #   a width cap (`max-w-[82%]`), a border, or the `prose` wrapper a Markdown
        #   body needs.
        def initialize(position: :start, color: nil, author: nil, timestamp: nil,
                       timestamp_format: :short, bubble_class: nil, **options)
          @position = position&.to_sym
          @color = color&.to_sym
          @author = author
          @timestamp = timestamp
          @timestamp_format = timestamp_format
          @bubble_class = bubble_class
          @options = options
        end

        # Slots set inside the render block only register once `content` runs, and
        # the avatar and the header are emitted *before* the bubble. Without this
        # they would be asked about while still unset, and silently skipped.
        def before_render
          content
        end

        def render_header?
          header? || author.present? || timestamp_text.present?
        end

        def timestamp_text
          return if timestamp.blank?

          @timestamp_text ||= if timestamp.respond_to?(:strftime)
            I18n.l(timestamp, format: timestamp_format)
          else
            timestamp.to_s
          end
        end

        def timestamp_datetime
          timestamp.iso8601 if timestamp.respond_to?(:iso8601)
        end

        private

        attr_reader :position, :color, :author, :timestamp, :timestamp_format,
                    :bubble_class, :options

        def message_attributes
          prepend_class_name(
            options.dup,
            class_names("chat", POSITIONS.fetch(position, POSITIONS[:start]))
          )
        end

        def bubble_classes
          class_names("chat-bubble", COLORS[color], bubble_class)
        end
      end
    end
  end
end
