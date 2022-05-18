# frozen_string_literal: true

module Bali
  module Table
    module Footer
      class Component < ApplicationViewComponent
        def initialize(options = {})
          @options = hyphenize_keys(options)
        end

        def call
          tag.tr(content, **@options)
        end
      end
    end
  end
end
