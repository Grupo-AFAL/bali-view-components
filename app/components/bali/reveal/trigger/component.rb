# frozen_string_literal: true

module Bali
  module Reveal
    module Trigger
      class Component < ApplicationViewComponent
        attr_reader :title, :options

        def initialize(title:, **options)
          @title = title
          @title_class = options.delete(:title_class)

          @options = prepend_class_name(options, 'reveal-trigger')
          @options = prepend_action(@options, 'click->reveal#toggle')
        end
      end
    end
  end
end
