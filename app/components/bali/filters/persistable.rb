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

      # El DataTable pinta el marcador como control propio de la toolbar y apaga este: dos
      # controladores `filter-persistence` sobre el mismo storage_id se pisan el localStorage
      # y la cookie. Apaga SOLO el toggle — el form sigue necesitando storage_id y
      # persist_enabled (la leyenda "Auto-guardado" del panel sale de ahí).
      def persistence_toggle?
        @persistence_toggle
      end
    end
  end
end
