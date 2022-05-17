# frozen_string_literal: true

module Bali
  module Table
    module Footer
      class Component < ApplicationViewComponent
        def initialize(options = {})
          @options = options.transform_keys { |k| k.to_s.gsub('_', '-') }
        end

        def call
          tag.tr(content, **@options)
        end
      end
    end
  end
end
