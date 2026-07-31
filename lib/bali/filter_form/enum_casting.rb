# frozen_string_literal: true

module Bali
  class FilterForm
    # EnumCasting traduce ETIQUETAS de enum a sus VALORES antes de que los params lleguen a
    # Ransack.
    #
    # Síntoma: filtrar Status = "Done" devolvía exactamente los registros contrarios.
    # Causa: Ransack castea con el tipo CRUDO de la columna (Ransack::Nodes::Value#cast vía
    # Context#type_for, que lee `column.type` y nunca el EnumType de ActiveRecord), así que
    # sobre un enum entero `"done".to_i` es 0 — el valor de `draft`. `AR.where(status: "done")`
    # acierta porque ahí sí corre EnumType; el mismo valor por Ransack no. Y falla INVERTIDO y
    # en silencio: "draft" también castea a 0, así que la mitad de los filtros parecen andar.
    #
    # Sobre enums de STRING esto ya funcionaba (cast_to_string no rompe la etiqueta y el
    # EnumType la resuelve después), así que traducir ahí es idempotente: `"action"` y
    # `"Action"` producen el mismo SQL. La traducción no lo cambia, solo lo hace explícito.
    module EnumCasting
      extend ActiveSupport::Concern

      # Los predicados donde el valor ES un miembro del enum. NO es una lista arbitraria: es
      # exactamente la que la UI avanzada ofrece para un atributo `type: :select`
      # (Bali::Filters::Operators.select_operators) — un test las clava juntas para que no
      # puedan separarse. Fuera de acá el valor no es una pertenencia y traducirlo cambiaría
      # la pregunta: `_cont` pide un SUBSTRING (sobre `enum kind: { a: "alpha" }`, buscar "a"
      # se convertiría en buscar "alpha"), y `_gteq` pide un ORDEN sobre los códigos crudos,
      # un significado que Rails no promete y que Bali no puede inventar.
      EQUALITY_PREDICATES = %w[eq not_eq in not_in].freeze

      # Llaves de Ransack que NO son condiciones: el combinador, los sorts y la forma `c`
      # (condiciones como array), que Bali no emite y que tiene otra estructura entera.
      RESERVED_KEYS = %w[m s c].freeze

      # Los groupings anidan: un grupo puede traer otro `g` adentro.
      GROUPING_KEYS = %w[g groupings].freeze

      # Sufijo de los predicados compuestos (`status_eq_any`), que preguntan lo mismo que su
      # predicado base sobre varios valores.
      COMPOUND_SUFFIX = /_(any|all)\z/

      private

      def cast_enum_labels(params)
        params.each_with_object({}) do |(key, value), casted|
          name = key.to_s
          casted[key] =
            if GROUPING_KEYS.include?(name)
              cast_enum_groupings(value)
            elsif RESERVED_KEYS.include?(name)
              value
            else
              cast_enum_condition(name, value)
            end
        end
      end

      # Un `g` ANIDADO puede llegar como array (Ransack acepta las dos formas y la
      # normalización de FilterForm#extract_groupings solo alcanza al nivel de arriba): sin
      # esta rama el grupo interno esquivaba la traducción y devolvía los registros contrarios.
      def cast_enum_groupings(groupings)
        return groupings.map { |group| cast_enum_group(group) } if groupings.is_a?(Array)
        return groupings unless groupings.is_a?(Hash)

        groupings.transform_values { |group| cast_enum_group(group) }
      end

      def cast_enum_group(group)
        group.is_a?(Hash) ? cast_enum_labels(group) : group
      end

      def cast_enum_condition(key, value)
        predicate = Ransack::Predicate.detect_from_string(key)
        return value if predicate.nil?
        return value unless EQUALITY_PREDICATES.include?(predicate.sub(COMPOUND_SUFFIX, ""))

        mapping = enum_mappings[key.delete_suffix("_#{predicate}")]
        return value if mapping.nil?

        return value.map { |member| cast_enum_member(mapping, member) } if value.is_a?(Array)

        cast_enum_member(mapping, value)
      end

      # Tres casos, no dos. Una ETIQUETA conocida se traduce. Un valor CRUDO conocido pasa
      # intacto, así que una app que ya mandaba `0`/`1` sigue andando igual. Y cualquier OTRA
      # cosa sobre un enum de enteros se convierte en un centinela que no puede casar con
      # nadie: dejarla pasar es reintroducir el bug entero, porque Ransack la castea con el
      # tipo crudo de la columna y `"completed".to_i` —un miembro renombrado, un `"Done"` con
      # mayúscula, un typo— es 0, o sea el PRIMER miembro del enum. Con el centinela, `eq`/`in`
      # no devuelven nada y `not_eq`/`not_in` devuelven todo: la respuesta honesta a una
      # pregunta sobre un miembro que no existe, en vez de la respuesta de otro miembro.
      #
      # Un enum de STRING no necesita centinela (una etiqueta desconocida ya no casa con
      # nada), y un valor VACÍO tampoco puede tenerlo: Ransack ignora las condiciones en
      # blanco, así que mapearlo convertiría un select sin elegir en "no muestres nada".
      def cast_enum_member(mapping, value)
        return value unless value.is_a?(String) || value.is_a?(Symbol)
        return value if value.blank?

        member = value.to_s
        return mapping[member] if mapping.key?(member)
        return value if mapping.values.any? { |raw| raw.to_s == member }
        return value unless mapping.values.all?(Integer)

        mapping.values.max + 1
      end

      # `defined_enums` y no `scope.model`: una relation lo delega en su clase, pero un scope
      # que YA es la clase (`FilterForm.new(Movie, params)` — la forma que la propia API de
      # Ransack enseña) no responde a `model`, y preguntando por ahí el módulo entero se
      # volvía un no-op silencioso con el bug original intacto. Un scope sin enums (los dobles
      # de los tests) tampoco responde y el módulo es un no-op, que es lo correcto: no hay
      # nada que traducir.
      #
      # Solo los enums del PROPIO modelo. Un `studio_status_eq` apunta al enum del modelo
      # asociado, y resolverlo obliga a replicar la resolución de asociaciones de Ransack
      # (multinivel, `ransackable_associations`, sufijos polimórficos): equivocarse ahí
      # reintroduce exactamente el bug de datos-incorrectos-con-cara-de-correctos que esto
      # arregla. Queda fuera a propósito y el gancho para extenderlo es este método — hasta
      # entonces, un select sobre el enum de una ASOCIACIÓN devuelve los registros contrarios
      # y hay que declarar sus `options:` con los valores crudos.
      def enum_mappings
        @enum_mappings ||= scope.respond_to?(:defined_enums) ? scope.defined_enums : {}
      end
    end
  end
end
