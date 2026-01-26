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
          @formats.map { |f| f.to_s.start_with?('.') ? f : ".#{f}" }.join(', ')
        end

        def button_classes
          class_names(
            'absolute -bottom-1 -right-1',
            'w-10 h-10 rounded-full',
            'flex justify-center items-center',
            'bg-base-200 hover:bg-base-300 cursor-pointer',
            'transition-colors duration-200',
            'focus-within:ring-2 focus-within:ring-primary focus-within:ring-offset-2'
          )
        end

        def avatar_options
          @options.merge(size: @size, shape: @shape)
        end
      end
    end
  end
end
