# frozen_string_literal: true

module Bali
  module Clipboard
    module Trigger
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'clipboard-trigger btn btn-ghost ' \
                       'rounded-l-none rounded-r-lg border border-base-300 ' \
                       'hover:bg-base-200 transition-colors'

        attr_reader :text

        def initialize(text = nil, square: nil, **options)
          @text = text
          @square = square
          @options = options
        end

        private

        attr_reader :options

        def trigger_classes
          class_names(
            BASE_CLASSES,
            { 'btn-square' => square? },
            options[:class]
          )
        end

        def trigger_attributes
          opts = options.except(:class)
          opts[:class] = trigger_classes
          opts = prepend_data_attribute(opts, 'clipboard-target', 'button')
          opts = prepend_action(opts, 'click->clipboard#copy')
          opts[:type] = :button
          opts[:'aria-label'] ||= default_aria_label
          opts
        end

        # Auto-detect if button should be square (icon-only, no text)
        def square?
          return @square unless @square.nil?

          text.blank?
        end

        def default_aria_label
          I18n.t('view_components.bali.clipboard.copy_label', default: 'Copy to clipboard')
        end
      end
    end
  end
end
