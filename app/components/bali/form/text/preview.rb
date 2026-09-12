# frozen_string_literal: true

module Bali
  module Form
    module Text
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic text input field with DaisyUI styling.
        def default
          render_with_template(
            template: 'bali/form/text/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the text field with validation error styling.
        def with_errors
          form_record.errors.add(:text, :invalid)

          render_with_template(
            template: 'bali/form/text/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Addons
        # Shows text field with left and right addons using DaisyUI join pattern.
        def with_addons
          render_with_template(
            template: 'bali/form/text/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Addons and Errors
        # Shows text field with addons and validation error.
        def with_addons_and_errors
          form_record.errors.add(:text, :invalid)

          render_with_template(
            template: 'bali/form/text/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Character Counter
        # @param max_length number
        # `char_counter:` on a text field — the same option, controller and
        # counter element the textarea has: an `<input>` and a `<textarea>` are
        # the same thing to a controller that only reads `value.length`.
        # `{ max: n }` counts against a maximum, `true` just counts.
        def with_char_counter(max_length: 40)
          render_with_template(
            template: 'bali/form/text/previews/with_char_counter',
            locals: { model: form_record, max_length: max_length.to_i }
          )
        end

        # @label With Auto Grow
        # `auto_grow:` belongs to the textarea — an `<input>` has no height to
        # grow into. A text field written with it gets the shared controller on
        # its wrapper and no input target, so the option is inert; this scenario
        # exists to hold it to being inert *quietly*, rather than throwing on
        # connect.
        def with_auto_grow
          render_with_template(
            template: 'bali/form/text/previews/with_auto_grow',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Shows text field with help text below the input.
        def with_help_text
          render_with_template(
            template: 'bali/form/text/previews/with_help_text',
            locals: { model: form_record }
          )
        end

        # @label With Help Text and Errors
        # Both messages render together: the error says what went wrong, the help
        # still says what is expected.
        def with_help_text_and_errors
          form_record.errors.add(:text, :invalid)

          render_with_template(
            template: 'bali/form/text/previews/with_help_text',
            locals: { model: form_record }
          )
        end

        # @label With External Error
        # A model-less form (`form_with url:` — the rodauth shape): `error:`
        # carries the message a non-ActiveModel validator produced. Strings and
        # arrays both work; nil/false render nothing, so the raw return of the
        # validator can be passed unconditionally.
        def with_external_error
          render_with_template(
            template: 'bali/form/text/previews/with_external_error'
          )
        end

        # @label Sizes
        # `size:` with a Symbol is the daisyUI density variant; an Integer keeps
        # meaning the HTML `size` attribute (width in characters).
        def sizes
          render_with_template(
            template: 'bali/form/text/previews/sizes'
          )
        end
      end
    end
  end
end
