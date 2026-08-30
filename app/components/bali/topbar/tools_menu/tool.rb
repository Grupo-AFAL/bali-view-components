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
      # se está renderizando, no `Rails.application.routes.url_helpers`. Además de evitar
      # el estado global, el contexto de vista resuelve los proxies de engine
      # (`main_app.`, etc.) que el objeto global NO incluye.
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
