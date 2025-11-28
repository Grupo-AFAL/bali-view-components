# frozen_string_literal: true

module Bali
  module DataTable
    module Action
      class Component < ApplicationViewComponent
        renders_one :description

        def initialize(href:, method: :get, **options)
          @method = method
          @href = href
          @options = options
        end

        private

        def link_klass
          @method&.to_sym == :delete ? DeleteLink::Component : Link::Component
        end
      end
    end
  end
end
