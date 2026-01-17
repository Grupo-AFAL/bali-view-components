# frozen_string_literal: true

module Bali
  module Clipboard
    module Trigger
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'btn btn-ghost clipboard-trigger join-item'

        def initialize(text = '', **options)
          @text = text
          @options = options
        end

        def call
          tag.button(**trigger_attributes) do
            text.presence || content
          end
        end

        private

        attr_reader :text, :options

        def trigger_attributes
          opts = prepend_class_name(options, BASE_CLASSES)
          opts = prepend_data_attribute(opts, 'clipboard-target', 'button')
          opts = prepend_action(opts, 'click->clipboard#copy')
          opts[:type] = :button
          opts[:'aria-label'] ||= default_aria_label
          opts
        end

        def default_aria_label
          I18n.t('view_components.bali.clipboard.copy_label', default: 'Copy to clipboard')
        end
      end
    end
  end
end
