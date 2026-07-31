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

      def cast_enum_groupings(groupings)
        return groupings unless groupings.is_a?(Hash)

        groupings.transform_values do |group|
          group.is_a?(Hash) ? cast_enum_labels(group) : group
        end
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

      # Un valor que NO es etiqueta pasa intacto: puede ser el valor crudo (una app que ya
      # mandaba `0`/`1` sigue andando igual) o un typo, y adivinar sobre un typo es la clase
      # de error que este módulo existe para no cometer. Ransack ya lo castea como siempre.
      def cast_enum_member(mapping, value)
        return value unless value.is_a?(String) || value.is_a?(Symbol)

        mapping.fetch(value.to_s, value)
      end

      # Solo los enums del PROPIO modelo. Un `studio_status_eq` apunta al enum del modelo
      # asociado, y resolverlo obliga a replicar la resolución de asociaciones de Ransack
      # (multinivel, `ransackable_associations`, sufijos polimórficos): equivocarse ahí
      # reintroduce exactamente el bug de datos-incorrectos-con-cara-de-correctos que esto
      # arregla. Queda fuera a propósito; el gancho para extenderlo es este método.
      #
      # El scope puede no ser un ActiveRecord::Relation (los tests usan dobles) — sin modelo
      # no hay enums y el módulo es un no-op.
      def enum_mappings
        return @enum_mappings if defined?(@enum_mappings)

        model = scope.respond_to?(:model) ? scope.model : nil
        @enum_mappings = model.respond_to?(:defined_enums) ? model.defined_enums : {}
      rescue StandardError
        @enum_mappings = {}
      end
    end
  end
end
