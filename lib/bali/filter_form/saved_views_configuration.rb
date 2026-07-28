# frozen_string_literal: true

module Bali
  class FilterForm
    # SavedViewsConfiguration — combinaciones de filtros CON NOMBRE (vistas guardadas).
    #
    # El FilterForm define el QUÉ del storage, no el DÓNDE (mismo espíritu que la
    # persistencia vía Rails.cache). `saved_views_store:` acepta cualquier objeto con este
    # contrato:
    #
    #   store.list                   -> [view, ...]     # vistas visibles para el usuario actual
    #   store.find(id)               -> view | nil
    #   store.save(name:, payload:)  -> view            # upsert por nombre
    #   store.delete(id)             -> void
    #
    # donde cada `view` responde a `id`, `name` y `payload` (Hash con las llaves de
    # PAYLOAD_KEYS). El FilterForm solo LEE (list/find): guardar/renombrar/borrar los hace
    # el controller dueño de la URL que recibe la UI (Bali::DataTable::SavedViews).
    #
    # El engine TRAE la implementación default de ese contrato: `saved_views_store: :default`
    # resuelve a `Bali::SavedView::Store` (tabla `bali_saved_views`, instalada con
    # `bin/rails bali:install:migrations`), scoped al `saved_views_owner:` que pasa la app
    # (p.ej. current_user) y al `storage_id:` del form; las mutaciones las atiende
    # `Bali::SavedViewsController` (rutas del engine montado). Una app puede seguir pasando
    # su propio store — p.ej. "vistas compartidas por equipo" es OTRA implementación del
    # mismo contrato (scoped al equipo en vez del usuario), sin tocar Bali.
    #
    # Aplicación: `?saved_view=<id>` en la URL. El payload REEMPLAZA el estado de filtros
    # (una vista es un estado completo, no un merge) y después pasa por la persistencia
    # normal de `fetch_stored_filter_state`, así que la vista aplicada se convierte en el
    # "último estado" del listado al navegar de regreso.
    module SavedViewsConfiguration
      # Llaves permitidas del payload de una vista. `columns` (índices visibles del column
      # selector) lo agrega el Stimulus del dropdown al GUARDAR y lo consume el column
      # selector al APLICAR — el FilterForm solo lo transporta.
      PAYLOAD_KEYS = %w[attributes groupings combinator search_value group_by columns].freeze

      def saved_views_enabled?
        @saved_views_store.present?
      end

      # Memoizado: el dropdown lo consulta más de una vez por render (.any? y luego .each)
      # y cada llamada sin memo era un SELECT.
      def saved_views
        @saved_views ||= saved_views_enabled? ? Array(@saved_views_store.list) : []
      end

      # La vista aplicada por URL (?saved_view=<id>), o nil. Memoiza incluso el nil (un id
      # borrado/ajeno no debe re-consultar el store en cada llamada).
      def current_saved_view
        return @current_saved_view if defined?(@current_saved_view)

        @current_saved_view =
          (@saved_views_store.find(@saved_view_param) if saved_views_enabled? && @saved_view_param.present?)
      end

      # Índices de columnas visibles que la vista aplicada trae guardados (o nil): el
      # DataTable se los pasa al column selector para que el estado inicial sea el de la vista.
      def saved_view_columns
        current_saved_view && normalized_view_payload(current_saved_view)["columns"]
      end

      # ¿El estado ACTUAL del form (ya post-persistencia) equivale al payload de esta vista?
      # Compara normalizado: llaves String, sin `columns` (vive en el DOM) y sin valores
      # vacíos — así una vista aplicada sigue reconociéndose como activa aunque la URL ya no
      # traiga ?saved_view= (p.ej. tras navegar de regreso con el estado restaurado del cache).
      def view_matches_current_state?(view)
        comparable_view_state(normalized_view_payload(view)) ==
          comparable_view_state(current_view_payload)
      end

      # Mismo contrato para un estado que viene de una URL (los atajos estáticos del
      # dropdown): se le da la forma del payload y se compara igual.
      def state_matches_current_state?(payload)
        comparable_view_state(payload) == comparable_view_state(current_view_payload)
      end

      # Estado ACTUAL completo, listo para guardarse como vista. Sin `columns`: eso vive en
      # el DOM (column selector) y lo agrega el Stimulus del dropdown al momento de enviar.
      def current_view_payload
        {
          "attributes" => attributes.reject { |_k, v| v.nil? || v == "" || v == [] },
          "groupings" => @groupings,
          "combinator" => @combinator,
          "search_value" => @search_value,
          "group_by" => @group_by
        }.compact
      end

      private

      # `:default` = el storage del engine, scoped al owner y al storage_id del form. Sin
      # owner o sin storage_id no hay store (el dropdown no pinta): mejor apagado que un
      # scope mal armado. Un store explícito pasa intacto.
      def resolve_saved_views_store(store, owner)
        return store unless store == :default
        return nil unless owner.present? && storage_id.present?

        Bali::SavedView.store_for(owner, storage_id)
      end

      # Forma canónica para comparar estados: llaves String a fondo, sin `columns` y sin
      # valores vacíos (un payload guardado sin combinator y un estado actual con combinator
      # nil son el mismo estado).
      def comparable_view_state(payload)
        payload.to_h.deep_stringify_keys.except("columns").reject { |_k, v| v.blank? }
      end

      # El payload viene de un jsonb round-trip (llaves String) o de un Hash recién armado
      # (llaves Symbol): se normaliza a String y se recorta al contrato.
      def normalized_view_payload(view)
        payload = view.payload || {}
        payload = payload.to_h if payload.respond_to?(:to_h)
        payload.transform_keys(&:to_s).slice(*PAYLOAD_KEYS)
      end

      # Reemplaza el estado derivado de `q` con el de la vista aplicada. Devuelve el hash de
      # atributos filtrado por los declarados (mismo gate que el camino normal de params);
      # `group_by` re-pasa por el whitelist de resolve_group_by — un payload viejo con un
      # atributo retirado simplemente lo pierde, sin reventar.
      def apply_saved_view_state
        payload = normalized_view_payload(current_saved_view)
        @groupings = payload["groupings"]
        @combinator = payload["combinator"]
        @search_value = payload["search_value"]
        @group_by = resolve_group_by(payload["group_by"])
        (payload["attributes"] || {}).select { |k, _v| self.class.attribute_names.include?(k.to_s) }
      end
    end
  end
end
