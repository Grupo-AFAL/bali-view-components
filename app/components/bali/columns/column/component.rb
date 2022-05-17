# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        attr_reader :options

        def initialize(**options)
          @class = options.delete(:class)
          @options = options
        end

        def call
          tag.div(content, class: "column #{@class}", **options)
        end
      end
    end
  end
end
