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
      # `route_helper` se resuelve contra el contexto, y si el contexto no lo conoce, contra
      # su `main_app` — la caída que mantiene vivo el menú en una pantalla de engine pintada
      # con el layout del host (ver `resolver`). Lo que NO se puede expresar es un helper de
      # OTRO engine (`bali_auth_admin.bar_path`): sólo el host tiene proxy propio. Por eso
      # `initialize` exige que `route_helper` termine en `_path` o `_url` — cierra el caso
      # donde alguien pasa el proxy pelado (`:main_app`) y `href` filtraría el `RoutesProxy`
      # mismo en el atributo.
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

        # `route_helper` presente: existe si el contexto SABE RESOLVER ese helper — así es
        # como una herramienta se enciende sola en cuanto su ruta se monta, sin copiar aquí
        # la condición de ambiente del host.
        #
        # OJO con lo que esto NO cubre: un `constraints` en la ruta no impide que el helper
        # exista. La pregunta es "¿está montada?", no "¿este usuario pasa?".
        def available?(context)
          route_helper ? !resolver(context).nil? : href(context).present?
        end

        def href(context)
          return url.call unless route_helper

          resolver(context)&.public_send(route_helper)
        end

        # Quién sabe resolver este helper: el contexto mismo, o el `main_app` del contexto.
        #
        # El segundo caso NO es un adorno. Un engine que pinta sus pantallas con el layout
        # del host —`BaliAuth.configuration.admin_layout = "application"`, que es como las
        # cuatro apps del grupo sirven `/admin/auth/...`— renderiza ese layout, y este menú
        # con él, contra el contexto de vista del ENGINE. Ahí los helpers del host no
        # existen: medido en gobierno-corporativo sobre `BaliAuth::Admin::RolesController`,
        # `respond_to?(:mission_control_jobs_path)` es `false` y
        # `main_app.mission_control_jobs_path` devuelve `/admin/jobs`.
        #
        # Sin esta caída, migrar a este componente APAGA en silencio las herramientas
        # montadas justo en esas pantallas —las externas siguen, porque su `url:` no
        # consulta rutas—, y el menú queda a medias sin ningún error que lo delate. El host
        # ya escribe `main_app.` en el resto de ese mismo topbar por esta razón.
        #
        # El contexto directo gana: en una pantalla del host `main_app` ni se consulta, así
        # que esto no puede cambiar lo que ya resolvía. Y la regla del router se conserva
        # entera — `RoutesProxy#respond_to?` responde `false` para un helper que no existe,
        # igual que el contexto.
        private def resolver(context)
          return context if context.respond_to?(route_helper)

          proxy = context.main_app if context.respond_to?(:main_app)
          proxy if proxy.respond_to?(route_helper)
        end

        def in_app? = in_app

        def new_tab? = !in_app?
      end
    end
  end
end
