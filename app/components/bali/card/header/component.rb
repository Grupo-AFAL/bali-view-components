# frozen_string_literal: true

module Bali
  module Card
    module Header
      class Component < ApplicationViewComponent
        renders_one :badge

        def initialize(title:, subtitle: nil, icon: nil, **options)
          @title = title
          @subtitle = subtitle
          @icon = icon
          @options = options
        end

        def call
          tag.div(class: header_classes, **@options.except(:class)) do
            safe_join([
              render_icon,
              render_titles,
              badge
            ].compact)
          end
        end

        private

        def header_classes
          class_names('flex items-center gap-3', @options[:class])
        end

        def render_icon
          return unless @icon

          render Bali::Icon::Component.new(@icon, class: 'size-6 shrink-0')
        end

        def render_titles
          tag.div do
            safe_join([
              tag.h2(@title, class: 'card-title'),
              render_subtitle
            ].compact)
          end
        end

        def render_subtitle
          return unless @subtitle

          tag.p(@subtitle, class: 'text-sm text-base-content/70')
        end
      end
    end
  end
end
