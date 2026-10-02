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
        def button_classes
          class_names(
            "absolute -bottom-1 -right-1",
            "w-10 h-10 rounded-full bg-base-100",
            "flex justify-center items-center",
            "focus-within:ring-2 focus-within:ring-primary focus-within:ring-offset-2"
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
      end
    end
  end
end
