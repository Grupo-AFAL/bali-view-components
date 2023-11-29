# frozen_string_literal: true

module Bali
  module BulkActions
    module Action
      class Component < ApplicationViewComponent
        attr_reader :name, :href, :method, :options

        def initialize(name:, href:, method: :post, **options)
          @name = name
          @href = href
          @method = method&.to_sym
          @options = options
        end
      end
    end
  end
end
