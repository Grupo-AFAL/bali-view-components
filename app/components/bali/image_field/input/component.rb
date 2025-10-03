# frozen_string_literal: true

module Bali
  module ImageField
    module Input
      class Component < ApplicationViewComponent
        def initialize(
          form:, method:, formats: %i[jpg jpeg png webp], icon_name: 'camera',
          container_options: {}, **options
        )
          @form = form
          @method = method
          @formats = formats
          @icon_name = icon_name

          @container_options = prepend_class_name(container_options, 'image-input-container')

          @options = prepend_data_attribute(options, 'image-field-target', 'input')
          @options = prepend_action(@options, 'change->image-field#show')
        end

        def accepted_formats
          @formats.map { |f| ".#{f}," }
        end
      end
    end
  end
end
