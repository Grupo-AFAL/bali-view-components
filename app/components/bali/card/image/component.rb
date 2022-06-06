# frozen_string_literal: true

module Bali
  module Card
    module Image
      class Component < ApplicationViewComponent
        attr_reader :src, :options

        def initialize(src:, **options)
          @src = src
          @figure_class = options.delete(:figure_class) || 'is-2by1'
          @options = prepend_class_name(options, 'card-image')
        end

        def add_class(class_name)
          @option = prepend_class_name(@options, class_name)
        end

        def tag_name
          options[:href].present? ? :a : :div
        end
      end
    end
  end
end
