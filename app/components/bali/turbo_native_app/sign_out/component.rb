# frozen_string_literal: true

module Bali
  module TurboNativeApp
    module SignOut
      class Component < ApplicationViewComponent
        def initialize(**options)
          @name = options.delete(:name)
          @confirm_message = options.delete(:confirm)

          @options = prepend_class_name(options, 'turbo-native-app-sign-out-component button')
          @options = prepend_controller(@options, 'turbo-native-app-sign-out')
          @options = prepend_action(@options, 'turbo-native-app-sign-out#perform')
          @options[:type] = 'button'
        end

        def call
          @options = prepend_data_attribute(
            @options, 'turbo-native-app-sign-out-confirmation-message-value', confirm_message
          )

          tag.button(name, **@options)
        end

        private

        def name
          @name || I18n.t('view_components.bali.turbo_native_app.sign_out.name')
        end

        def confirm_message
          @confirm_message || I18n.t('view_components.bali.turbo_native_app.sign_out.confirm')
        end
      end
    end
  end
end
