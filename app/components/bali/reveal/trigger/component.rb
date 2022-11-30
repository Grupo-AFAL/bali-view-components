# frozen_string_literal: true

module Bali
  module Reveal
    module Trigger
      class Component < ApplicationViewComponent
        attr_reader :title, :title_icon_url, :options

        def initialize(title:, show_border: true, title_icon_url: nil, **options)
          @title = title
          @title_icon_url = title_icon_url
          @title_class = options.delete(:title_class)
          @icon_class = options.delete(:icon_class)

          @options = prepend_class_name(options, 'reveal-trigger')
          @options = prepend_action(@options, 'click->reveal#toggle')

          @options = prepend_class_name(options, 'is-border-bottom') if show_border
        end
      end
    end
  end
end
