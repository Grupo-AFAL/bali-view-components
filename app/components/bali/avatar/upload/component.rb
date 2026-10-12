# frozen_string_literal: true

module Bali
  module Avatar
    module Upload
      class Component < ApplicationViewComponent
        ACCEPTED_FORMATS = %w[jpg jpeg png webp].freeze

        # rubocop:disable Metrics/ParameterLists
        def initialize(form:, method:, src: nil, formats: ACCEPTED_FORMATS,
                       size: :xl, shape: :circle, **options)
          @form = form
          @method = method
          @src = src
          @formats = Array(formats)
          @size = size&.to_sym
          @shape = shape&.to_sym
          @options = options
        end
        # rubocop:enable Metrics/ParameterLists

        def accepted_formats
          @formats.map { |f| f.to_s.start_with?(".") ? f : ".#{f}" }.join(", ")
        end

        # The tint is the label's, over the button's opaque base-100: the button sits on the
        # picture's corner, and a translucent fill there let the photo show through.
        #
        # The input inside is invisible, so the ring is the button's. daisyUI only rings a
        # `.btn:has(:focus-visible)`, and `.btn` would restyle this button, so the same outline
        # (2px, offset 2px) is written out with `has-focus-visible:`.
        def button_classes
          class_names(
            "absolute -bottom-1 -right-1",
            "w-10 h-10 rounded-full bg-base-100",
            "flex justify-center items-center",
            "has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-primary"
          )
        end

        def label_classes
          class_names(
            "cursor-pointer flex items-center justify-center w-full h-full rounded-full",
            "bg-base-content/8 hover:bg-base-content/16 transition-colors duration-200"
          )
        end

        def avatar_options
          @options.merge(size: @size, shape: @shape)
        end

        # Rails' own field: Bali's `file_field` brings a `<label>` and a button of its own, and
        # nested that label inside this one.
        def raw_file_field
          options = {
            accept: accepted_formats,
            class: Bali::FormBuilder::FileFields::INPUT_CLASS,
            aria: { label: t(".upload_image") },
            data: { avatar_target: "input", action: "change->avatar#showImage" }
          }
          if @form.respond_to?(:rails_file_field)
            @form.rails_file_field(@method, @form.merge_aria_attributes(options, @method))
          else
            @form.file_field(@method, options)
          end
        end

        # Bali's builder only; the input's `aria-describedby` above points at it.
        def error_message
          @form.error_message(@method) if @form.respond_to?(:error_message)
        end
      end
    end
  end
end
