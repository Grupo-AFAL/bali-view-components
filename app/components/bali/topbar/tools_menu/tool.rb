# frozen_string_literal: true

module Bali
  module Topbar
    module ToolsMenu
      # Una herramienta del menú del topbar.
      #
      # Responde dos preguntas y ninguna más: "¿existe en este ambiente?" y "¿a dónde
      # apunta?". Quién la puede ver NO es asunto suyo — eso lo decide el host, que pasa la
      # lista ya filtrada (ver el spec: es lo que permite que apps con modelos de
      # autorización distintos usen el mismo componente).
      #
      # El `context` se RECIBE, no se busca. Es el contexto de vista donde el componente ya
      # se está renderizando, no `Rails.application.routes.url_helpers`. Evita el estado
      # global y se prueba con un doble, sin montar rutas.
      #
      # Límite: `route_helper` tiene que ser un helper al que el contexto responda
      # DIRECTAMENTE. Uno detrás de un proxy de engine (`main_app.foo_path`,
      # `bali_auth_admin.bar_path`) no se puede expresar hoy — por eso `initialize` exige
      # que termine en `_path` o `_url`: cierra el caso donde alguien pasa el proxy pelado
      # (`:main_app`) y `href` filtraría el `RoutesProxy` mismo en el atributo.
      Tool = Data.define(:key, :icon, :route_helper, :url, :in_app, :name, :meta) do
        def initialize(key:, icon:, route_helper: nil, url: nil, in_app: false, name: nil, meta: {})
          if route_helper && url
            raise ArgumentError,
                  "`route_helper:` and `url:` are exclusive: a tool is either mounted in the " \
                  "host app (route_helper) or lives elsewhere (url)."
          end

          if route_helper.nil? && url.nil?
            raise ArgumentError,
                  "a tool needs `route_helper:` (mounted in the host app) or `url:` (a lambda " \
                  "returning an external URL)."
          end

          if route_helper && !route_helper.to_s.end_with?("_path", "_url")
            raise ArgumentError,
                  "`route_helper:` has to be a route helper name ending in `_path` or " \
                  "`_url` (e.g. `:mission_control_jobs_path`). `#{route_helper.inspect}` " \
                  "looks like an engine proxy (`main_app`, `bali_auth_admin`), not a " \
                  "helper — the proxy itself responds to `respond_to?`, and `href` would " \
                  "return it verbatim instead of a URL."
          end

          super
        end

        # `route_helper` presente: existe si el contexto conoce ese helper — así es como una
        # herramienta se enciende sola en cuanto su ruta se monta, sin copiar aquí la
        # condición de ambiente del host.
        #
        # OJO con lo que esto NO cubre: un `constraints` en la ruta no impide que el helper
        # exista. La pregunta es "¿está montada?", no "¿este usuario pasa?".
        def available?(context)
          route_helper ? context.respond_to?(route_helper) : href(context).present?
        end

        def href(context)
          route_helper ? context.public_send(route_helper) : url.call
        end

        def in_app? = in_app

        def new_tab? = !in_app?
      end
    end
  end
end
