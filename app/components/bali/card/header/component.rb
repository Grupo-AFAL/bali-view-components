# frozen_string_literal: true

module Bali
  module Card
    module Header
      class Component < ApplicationViewComponent
        attr_reader :title, :options

        def initialize(title:, **options)
          @title = title
          @options = prepend_class_name(options, 'card-header')
        end
      end
    end
  end
end
