# frozen_string_literal: true

module Bali
  module Card
    module Action
      class Component < ApplicationViewComponent
        def initialize(href: nil, **options)
          @href = href
          @options = options
        end

        def call
          if @href.present?
            tag.a(href: @href, class: action_classes, **@options.except(:class)) { content }
          else
            tag.button(type: 'button', class: action_classes, **@options.except(:class)) { content }
          end
        end

        private

        def action_classes
          class_names('btn', @options[:class])
        end
      end
    end
  end
end
