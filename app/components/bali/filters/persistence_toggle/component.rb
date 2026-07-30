# frozen_string_literal: true

module Bali
  module Filters
    module PersistenceToggle
      # El marcador que decide si los filtros se recuerdan entre visitas.
      #
      # Vive suelto y no dentro del panel de filtros porque en la toolbar del DataTable es un
      # control propio —"cómo se recuerda el estado"— y no un botón del panel. Los hosts que
      # usan Filters/SimpleFilters sin DataTable lo siguen recibiendo desde ahí.
      #
      # INVARIANTE: UN solo toggle por listado. Dos controladores `filter-persistence` sobre
      # el mismo storage_id se pisan el localStorage y la cookie, y el segundo deja al usuario
      # sin saber cuál de los dos manda.
      class Component < ApplicationViewComponent
        # @param storage_id [String] Identidad del listado; sin ella no hay dónde guardar
        # @param enabled [Boolean] Si el usuario ya optó por persistir
        def initialize(storage_id:, enabled: false)
          @storage_id = storage_id
          @enabled = enabled
        end

        attr_reader :storage_id

        def render?
          storage_id.present?
        end

        def enabled?
          @enabled
        end

        # Claves EXISTENTES de `bali.filters.*`, leídas con `I18n.t` explícito y NO con
        # `t('.x')`: el helper de ViewComponent resuelve al scope sidecar
        # (`view_components.bali.filters.persistence_toggle.*`), así que usarlo acá sería
        # mudar las claves y dejar sin traducción, en silencio, a cualquier host que las
        # tenga sobrescritas.
        def enabled_tooltip
          I18n.t("bali.filters.persistence_enabled",
                 default: "Filters are being saved. Click to disable.")
        end

        def disabled_tooltip
          I18n.t("bali.filters.persistence_disabled",
                 default: "Filters are not saved. Click to enable.")
        end

        def tooltip
          enabled? ? enabled_tooltip : disabled_tooltip
        end

        def label
          I18n.t("bali.filters.persistence_label", default: "Remember filters")
        end
      end
    end
  end
end
