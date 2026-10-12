# frozen_string_literal: true

module Bali
  module Chat
    module Composer
      # The row a conversation is written in: the field, the mic, and send.
      #
      # It was the one piece of the chat every caller still hand-rolled. Both apps the
      # container came from write the same row, and so did this repo's own preview, under
      # a comment that said as much: "a chat composer is one unlabelled field in a row".
      # Three copies of a row is a component.
      #
      # It renders the ROW and not the form: the form's url, its method and whatever
      # Stimulus a host hangs off it (a reset after a successful submit, a confirm, a
      # rate-limit guard) are the host's, and a component that owned them would need an
      # escape hatch for each.
      #
      #   <% chat.with_footer do %>
      #     <%= form_with url: messages_path do %>
      #       <%= render Bali::Chat::Composer::Component.new(
      #             name: 'message[content]', placeholder: t('.write')) %>
      #     <% end %>
      #   <% end %>
      #
      # DICTATION IS ON. A composer is where speaking instead of typing earns its place,
      # so this is the one control in the library that starts with it: `dictation: false`
      # turns it off, and a host whose conversations carry data that may not leave should
      # do exactly that — the browser's recognition sends the audio to the BROWSER's
      # vendor (Google in Chrome, Microsoft in Edge, Apple in Safari). The field helper's
      # own `dictation:` stays opt-in; a general-purpose field has no business presuming.
      #
      # The mic is written `hidden` and `speech-input` reveals it only where the browser
      # has recognition, so there is nothing to feature-detect at the call site.
      class Component < ApplicationViewComponent
        # Anything else that belongs in the row — an attach button, a model picker —
        # rendered between the field and send.
        renders_many :actions

        # Dictation into a textarea that grows: the two options are written for each
        # other, and growing is the browser's (`field-sizing`) rather than a controller
        # writing an inline height, which is what `auto_grow` had to undo on a reset.
        FIELD_CLASS = "textarea w-full resize-none field-sizing-content max-h-48 overflow-y-auto"

        # @param name [String] `name` of the field — `'message[content]'`, or whatever the
        #   action reads.
        # @param placeholder [String, nil] Placeholder for the field.
        # @param submit [String, nil] Label for the send button; the translation by default.
        # @param rows [Integer] Starting height, and the floor it returns to.
        # @param dictation [Boolean, Hash] `false` to drop the mic, or `{ lang: 'en-US' }`
        #   to say which language is being spoken. See the note above before turning it on
        #   anywhere the conversation is confidential.
        # @param field_options [Hash] Straight onto the `<textarea>` — `required`, `id`,
        #   `maxlength`, a `data` of the host's own.
        # @param submit_options [Hash] Straight onto the send button. A composer's send is where
        #   a host hangs its own Stimulus (`chat#showTyping`, a confirm) or its own class, so it
        #   takes attributes rather than being sealed.
        def initialize(name:, placeholder: nil, submit: nil, rows: 2, dictation: true,
                       field_options: {}, submit_options: {}, **options)
          @name = name
          @placeholder = placeholder
          @submit = submit
          @rows = rows
          @dictation = dictation
          @field_options = field_options
          @submit_options = submit_options
          @options = options
        end

        private

        attr_reader :name, :placeholder, :submit, :rows, :dictation, :field_options,
                    :submit_options, :options

        def dictation? = dictation.present?

        def dictation_lang = dictation.is_a?(Hash) ? dictation[:lang] : nil

        def submit_label = submit || I18n.t("bali_view.chat.composer.send")

        def dictate_label = t("bali_view.form_builder.dictation.dictate")

        def unavailable_label = t("bali_view.form_builder.dictation.unavailable")

        # The outer element: the host's classes and, when there is dictation, the controller
        # that has to contain the field, the mic and the status line alike.
        def wrapper_attributes
          attrs = prepend_class_name(options.dup, "bali-chat-composer")
          return attrs unless dictation?

          attrs = prepend_controller(attrs, "speech-input")
          dictation_lang ? prepend_values(attrs, "speech-input", lang: dictation_lang) : attrs
        end

        def submit_attributes
          attrs = submit_options.deep_dup
          attrs[:type] = "submit"
          attrs[:class] = class_names("btn btn-primary shrink-0", attrs[:class])
          attrs
        end

        def field_attributes
          attrs = field_options.deep_dup
          attrs[:rows] = rows
          attrs[:placeholder] = placeholder || I18n.t("bali_view.chat.composer.placeholder")
          attrs[:class] = class_names(FIELD_CLASS, attrs[:class])
          return attrs unless dictation?

          attrs = prepend_data_attribute(attrs, :'speech-input-target', "input")
          prepend_action(attrs, "input->speech-input#typed")
        end
      end
    end
  end
end
