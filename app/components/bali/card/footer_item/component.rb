# frozen_string_literal: true

module Bali
  module Card
    module FooterItem
      class Component < ApplicationViewComponent
        attr_reader :options

        def initialize(**options)
          @options = options
        end

        def call
          if options[:href].present?
            tag.a(**prepend_class_name(options, 'btn')) do
              content
            end
          else
            tag.div(**options) do
              content
            end
          end
        end
      end
    end
  end
end
