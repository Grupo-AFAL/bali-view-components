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

      # La vista de la que VIENE el estado actual, aunque ya se le hayan cambiado filtros.
      # A diferencia de {#current_saved_view}, esto no aplica nada: solo recuerda el origen
      # para poder ofrecer "Actualizar 'X'". Una vista borrada resuelve a nil sin romper.
      def saved_view_origin
        return @saved_view_origin if defined?(@saved_view_origin)

        @saved_view_origin =
          if saved_views_enabled? && @saved_view_origin_param.present?
            @saved_views_store.find(@saved_view_origin_param)
          end
      end

      # El id crudo, para que los forms y los links lo hagan viajar sin tocar el store.
      def saved_view_origin_id = @saved_view_origin_param

      # ¿El estado actual se DESVIÓ de la vista de la que viene? Es la única condición que
      # justifica ofrecer "Actualizar": sin cambios no hay nada que guardar.
      def saved_view_dirty?
        origin = saved_view_origin
        origin.present? && !view_matches_current_state?(origin)
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
      #
      # Un payload que normaliza a VACÍO nunca casa por estado: una vista "solo columnas" (o
      # "ver todo") describe el estado limpio, así que casaría en cada visita y se marcaría
      # activa sin que sus columnas estén aplicadas —columns solo se aplica con ?saved_view=—.
      # Esas vistas solo se reconocen activas cuando se aplican por URL.
      def view_matches_current_state?(view)
        state_matches_current_state?(normalized_view_payload(view))
      end

      # Mismo contrato para un estado que viene de una URL (los atajos estáticos del
      # dropdown): se le da la forma del payload y se compara igual.
      def state_matches_current_state?(payload)
        comparable = comparable_view_state(payload)
        return false if comparable.empty?

        comparable == comparable_view_state(current_view_payload)
      end

      # Estado ACTUAL completo, listo para guardarse como vista. Sin `columns`: eso vive en
      # el DOM (column selector) y lo agrega el Stimulus del dropdown al momento de enviar.
      def current_view_payload
        {
          "attributes" => attributes.reject { |_k, v| v.nil? || v == "" || v == [] },
          "groupings" => @groupings,
          "combinator" => @combinator,
          "search_value" => @search_value,
          # A String, no el Symbol de `resolve_group_by`: este payload se compara contra uno
          # que YA volvió de un jsonb, donde todo es String. `comparable_view_state` normaliza
          # las LLAVES pero no los valores, así que `:genre` nunca casaba con `"genre"` y una
          # vista que agrupa no se reconocía activa por estado — solo con `?saved_view=` puesto.
          "group_by" => @group_by&.to_s
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
      #
      # Los combinadores NO-OP también se descartan: el builder siempre re-emite `m` por grupo
      # (y `q[m]` arriba) aunque el estado original no lo trajera, así que sin esto un atajo o
      # una vista dejaban de reconocerse activos tras el primer round-trip por el popover o el
      # buscador. Solo se descarta donde el combinador no puede cambiar el resultado —un grupo
      # de una condición, o un solo grupo—, nunca cuando distingue de verdad AND de OR.
      def comparable_view_state(payload)
        state = payload.to_h.deep_stringify_keys.except("columns").reject { |_k, v| v.blank? }
        groupings = state["groupings"]
        if groupings.is_a?(Hash)
          state["groupings"] = groupings.transform_values do |group|
            group.is_a?(Hash) && group.except("m").size < 2 ? group.except("m") : group
          end
          state = state.except("combinator") if groupings.size < 2
        end
        state.reject { |_k, v| v.blank? }
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
        # Un `group_by` explícito en la URL gana sobre el del payload: con `?saved_view=` aún
        # pegado (los links de "Agrupar por" preservan la query), el payload pisaba el clic
        # recién dado y el control se veía muerto.
        @group_by = @group_by.presence || resolve_group_by(payload["group_by"])
        (payload["attributes"] || {}).select { |k, _v| self.class.attribute_names.include?(k.to_s) }
      end
    end
  end
end
