# frozen_string_literal: true

module Bali
  module Modal
    module Header
      class Component < ApplicationViewComponent
        def initialize(title:, badge: nil, badge_color: :primary, close_button: true,
                       modal_id: nil, **options)
          @title = title
          @badge = badge
          @badge_color = badge_color
          @close_button = close_button
          @modal_id = modal_id
          @options = options
        end

        def call
          tag.div(class: header_classes, **@options.except(:class)) do
            safe_join([
              render_title_section,
              render_close_button
            ].compact)
          end
        end

        private

        def header_classes
          class_names(
            'flex items-center justify-between gap-4 mb-4',
            @options[:class]
          )
        end

        def render_title_section
          tag.div(class: 'flex items-center gap-3 flex-1 min-w-0') do
            safe_join([
              render_title,
              render_badge
            ].compact)
          end
        end

        def render_title
          tag.h3(@title, id: title_id, class: 'text-lg font-bold truncate')
        end

        def render_badge
          return unless @badge

          render Bali::Tag::Component.new(text: @badge, color: @badge_color, size: :sm)
        end

        def render_close_button
          return unless @close_button

          tag.button(
            type: 'button',
            class: 'btn btn-sm btn-circle btn-ghost shrink-0',
            'aria-label': 'Close modal',
            'data-action': 'modal#close'
          ) { '✕' }
        end

        def title_id
          "#{@modal_id}-title" if @modal_id
        end
      end
    end
  end
end
