# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        attr_reader :options

        def initialize(**options)
          @options = prepend_class_name(options, 'column flex-1 min-w-0')
        end

        def call
          tag.div(content, **options)
        end
      end
    end
  end
end
