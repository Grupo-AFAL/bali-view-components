# frozen_string_literal: true

module Bali
  module TurboNativeApp
    module SignOut
      class Component < ApplicationViewComponent
        attr_reader :name, :options

        def initialize(**options)
          @name = options.delete(:name) || t('view_components.bali.turbo_native_app.sign_out.name')
          @confirm = options.delete(:confirm) ||
                     t('view_components.bali.turbo_native_app.sign_out.confirm')

          @options = prepend_class_name(options, 'turbo-native-app-sign-out-component button')
          @options = prepend_controller(@options, 'turbo-native-app-sign-out')
          @options = prepend_action(@options, 'turbo-native-app-sign-out#perform')
          @options = prepend_data_attribute(
            @options, 'turbo-native-app-sign-out-confirmation-message-value', @confirm
          )
          @options[:type] = 'button'
        end

        def call
          tag.button(name, **options)
        end
      end
    end
  end
end
