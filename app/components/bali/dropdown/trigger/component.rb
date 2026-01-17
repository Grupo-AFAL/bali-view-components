# frozen_string_literal: true

module Bali
  module Dropdown
    module Trigger
      class Component < ApplicationViewComponent
        VARIANTS = {
          button: 'btn',
          icon: 'btn btn-ghost btn-circle',
          ghost: 'btn btn-ghost',
          custom: ''
        }.freeze

        def initialize(variant: :button, **options)
          @variant = variant.to_sym
          @options = options
          @options[:tabindex] ||= 0
          @options[:role] ||= 'button'
          @options[:'aria-haspopup'] ||= 'true'
          @options[:'aria-expanded'] ||= 'false'
          @options[:data] ||= {}
          @options[:data][:dropdown_target] = 'trigger'
        end

        def call
          tag.div(**prepend_class_name(@options, base_classes)) do
            content
          end
        end

        private

        attr_reader :variant

        def base_classes
          VARIANTS.fetch(variant, VARIANTS[:button])
        end
      end
    end
  end
end
