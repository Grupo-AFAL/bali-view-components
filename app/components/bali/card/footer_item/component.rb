# frozen_string_literal: true

module Bali
  module Card
    module FooterItem
      class Component < ApplicationViewComponent
        attr_reader :options

        def initialize(**options)
          @options = prepend_class_name(options, 'card-footer-item')
        end

        def call
          tag.send(tag_name, **options) do
            content
          end
        end

        def tag_name
          options[:href].present? ? :a : :div
        end
      end
    end
  end
end
