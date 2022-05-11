# frozen_string_literal: true

module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
        attr_reader :title, :icon, :active, :options

        def initialize(title:, icon: nil, active: false, **options)
          @title = title
          @icon = icon
          @active = active

          @options = options
          @options = prepend_class_name(@options, 'is-hidden') unless @active
        end

        def call
          content
        end
      end
    end
  end
end
