# frozen_string_literal: true

module Bali
  module Table
    module Row
      class Component < ApplicationViewComponent
        def initialize(options = {})
          @skip_tr = options.delete(:skip_tr)
          @options = hyphenize_keys(options)
        end

        def call
          @skip_tr ? content : tag.tr(content, **@options)
        end
      end
    end
  end
end
