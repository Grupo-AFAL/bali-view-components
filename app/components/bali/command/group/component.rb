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
        # @param options [Hash] Extra HTML attributes (class, data, id) merged
        #   onto the group wrapper — the passthrough the slot lambda promises.
        def initialize(name:, mode: :searchable, **options)
          @name = name
          @mode = MODES.include?(mode) ? mode : :searchable
          @options = options
        end

        attr_reader :name, :mode

        # The wrapper's attributes with the host's `**options` merged: `data`
        # merges over the group's own command-target/mode data, `class` and the
        # rest pass through.
        def wrapper_options
          options = @options.dup
          data = { command_target: "group", mode: mode }.merge(options.delete(:data) || {})
          { data: data }.merge(options)
        end
      end
    end
  end
end
