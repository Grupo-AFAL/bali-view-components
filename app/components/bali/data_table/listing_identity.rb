# frozen_string_literal: true

module Bali
  module DataTable
    # La identidad del listado, compartida por los controles que persisten algo. El
    # DataTable la resuelve UNA sola vez y aquí se derivan las dos formas que consume el
    # JS. Antes cada control normalizaba el "#" por su cuenta, y el controlador de vistas
    # guardadas localiza al selector de columnas comparando la cadena EXACTA del atributo:
    # dos derivaciones separadas describían listados distintos y guardar una vista perdía
    # las columnas sin fallar en ningún lado.
    module ListingIdentity
      # Apunta al CONTENEDOR del DataTable, no a la <table>: la tabla puede no traer id
      # propio y el contenedor es el único nodo cuya identidad conoce el listado.
      def table_selector
        listing_id.presence && "##{listing_id} table"
      end

      def columns_storage_key
        listing_id.presence && "bali:columns:#{listing_id}"
      end
    end
  end
end
