# frozen_string_literal: true

module Bali
  module ImageField
    module Input
      class Component < ApplicationViewComponent
        DEFAULT_FORMATS = %i[jpg jpeg png webp].freeze
        DEFAULT_ICON = 'camera'
        private_constant :DEFAULT_FORMATS, :DEFAULT_ICON

        attr_reader :form, :field_name, :icon_name

        def initialize(form:, method:, formats: DEFAULT_FORMATS, icon_name: DEFAULT_ICON, **options)
          @form = form
          @field_name = method
          @formats = formats.freeze
          @icon_name = icon_name
          @options = options
        end

        private

        attr_reader :formats, :options

        def container_classes
          class_names(
            'image-input-container',
            'absolute inset-0 flex justify-center items-center cursor-pointer',
            'rounded-lg',
            'group-hover:bg-base-content/20 group-hover:backdrop-blur-sm',
            'max-md:bg-base-content/20 max-md:backdrop-blur-sm'
          )
        end

        def icon_classes
          class_names(
            'hidden',
            'group-hover:flex max-md:flex',
            'text-base-content'
          )
        end

        def input_options
          opts = options.dup
          opts[:accept] = accepted_formats
          opts[:class] = class_names('hidden', options[:class])
          prepend_data_attribute(
            prepend_action(opts, 'change->image-field#show'),
            'image-field-target',
            'input'
          )
        end

        def accepted_formats
          formats.map { |f| ".#{f}" }.join(', ')
        end
      end
    end
  end
end
