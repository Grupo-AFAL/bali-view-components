# frozen_string_literal: true

module Bali
  module Command
    module Group
      class Component < ApplicationViewComponent
        MODES = %i[searchable recent action].freeze

        renders_many :items, lambda { |**opts|
          Item::Component.new(mode: @mode, **opts)
        }

        # @param name [String] Group header label.
        # @param mode [Symbol] One of:
        #   - :searchable (default) — items only show when the query matches them
        #   - :recent — items only show when the query is empty
        #   - :action — items always show (used as a fallback for no-results)
        def initialize(name:, mode: :searchable)
          @name = name
          @mode = MODES.include?(mode) ? mode : :searchable
        end

        attr_reader :name, :mode
      end
    end
  end
end
