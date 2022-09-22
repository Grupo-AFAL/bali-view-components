# frozen_string_literal: true

module Bali
  module TurboNativeApp
    module SignOut
      class Preview < ApplicationViewComponentPreview
        # TurboNativeApp Sign Out
        # ---------------
        # Turbo native application sign out button
        # @param name [String]
        # @param confirm [String]
        def default(name: 'Sign out', confirm: 'Are you sure?')
          render Bali::TurboNativeApp::SignOut::Component.new(name: name, confirm: confirm)
        end
      end
    end
  end
end
