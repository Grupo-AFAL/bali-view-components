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
      # El id del CONTENEDOR que pinta el DataTable, derivable SIN construir el componente.
      # Es lo que un `.turbo_stream.erb` tiene que apuntar: ahí el host tiene el filter_form
      # pero no el DataTable, y apuntar al `storage_id` CRUDO fallaba en silencio cada vez
      # que el saneado cambiaba el valor — Turbo resuelve el target con getElementById, así
      # que sin nodo no reemplaza nada, no revienta y no loguea.
      #
      #   turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form)
      #
      # @param source [#storage_id, String, Symbol] el filter_form o el valor crudo
      def self.for(source)
        sanitize(source.respond_to?(:storage_id) ? source.storage_id : source)
      end

      # Slug usable como identificador CSS: sin "#" inicial, sin caracteres inválidos y sin
      # empezar con dígito — `#123 table` hace que querySelector lance SyntaxError. No se
      # hace downcase a propósito: el matching de `#id` en HTML es case-sensitive.
      def self.sanitize(value)
        slug = value.to_s.delete_prefix("#").gsub(/[^A-Za-z0-9_-]+/, "-").gsub(/\A-+|-+\z/, "")
        return if slug.blank?

        slug.match?(/\A\d/) ? "listing-#{slug}" : slug
      end

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
