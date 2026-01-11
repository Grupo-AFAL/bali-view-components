# frozen_string_literal: true

module Bali
  module Card
    module Header
      class Component < ApplicationViewComponent
        attr_reader :title, :options

        def initialize(title:, **options)
          @title = title
          @options = options
        end
      end
    end
  end
end
