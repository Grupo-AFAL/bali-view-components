# frozen_string_literal: true

module Bali
  module Filters
    # The persistence trio shared by `Filters::Component` and
    # `DataTable::SimpleFilters::Component`. `DataTable#capture_persistence`
    # coordinates both: it lifts the bookmark toggle out of whichever form is in
    # use and paints it once as a toolbar control.
    #
    # Includers must set `@storage_id`, `@persist_enabled` and
    # `@persistence_toggle` in their initializer.
    module Persistable
      attr_reader :storage_id, :persist_enabled

      # Returns true if persistence is available (storage_id is configured)
      def persistence_available?
        @storage_id.present?
      end

      # Returns true if user has enabled persistence
      def persist_enabled?
        @persist_enabled
      end

      # DataTable paints the bookmark as a toolbar control of its own and turns this one off:
      # two `filter-persistence` controllers over the same storage_id trample localStorage and
      # the cookie. It turns off the toggle ONLY — the form still needs storage_id and
      # persist_enabled (the panel's "Auto-saved" caption comes from there).
      def persistence_toggle?
        @persistence_toggle
      end
    end
  end
end
