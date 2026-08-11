# frozen_string_literal: true

module Bali
  module Command
    module Group
      class Component < ApplicationViewComponent
        MODES = %i[searchable navigation recent action].freeze

        renders_many :items, lambda { |**opts|
          Item::Component.new(mode: @mode, **opts)
        }

        # @param name [String] Group header label.
        # @param mode [Symbol] One of:
        #   - :searchable (default) — items only show when the query matches them
        #   - :navigation — the whole list while the query is empty, then
        #     filtered like :searchable. What a directory of pages wants:
        #     browsable the moment the palette opens AND narrowed as the user
        #     types. Reaching for :action to get the first half is what #1016
        #     was: the list showed up and then never filtered
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
