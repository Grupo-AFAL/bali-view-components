# frozen_string_literal: true

module Bali
  module Dropdown
    module Trigger
      class Component < ApplicationViewComponent
        # IMPORTANT: The `menu` variant is designed for use inside navbar menus.
        # It uses `!bg-transparent` to override DaisyUI's menu hover styling which
        # adds dark backgrounds that look bad on colored navbar backgrounds.
        # DO NOT add `btn` classes to `menu` variant - they break vertical alignment.
        VARIANTS = {
          button: 'btn',
          icon: 'btn btn-ghost btn-circle',
          ghost: 'btn btn-ghost',
          menu: 'flex items-center gap-1 cursor-pointer !bg-transparent hover:!bg-transparent',
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
