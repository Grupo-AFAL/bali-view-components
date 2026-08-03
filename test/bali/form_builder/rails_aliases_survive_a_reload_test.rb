# frozen_string_literal: true

require "test_helper"

# Tres helpers guardan el método de Rails bajo un nombre `rails_*` para poder publicar el
# suyo bajo el nombre canónico. Se guardaban con `alias`, que captura lo que el nombre
# resuelva EN ESE MOMENTO — y esos archivos se vuelven a ejecutar en cada reload de código,
# cuando el módulo de Bali YA está incluido. El alias pasaba entonces a apuntar al override
# de Bali y el helper se llamaba a sí mismo: `SystemStackError` en cada file field, cada text
# area y cada time zone select, desde el primer reload y hasta reiniciar el servidor (#840).
#
# La suite arrancaba en frío y nunca lo veía. Este test recarga los archivos a propósito.
class BaliFormBuilderRailsAliasesSurviveAReloadTest < FormBuilderTestCase
  # archivo => [nombre guardado, nombre de Rails]
  MODULES = {
    "file_fields" => %i[rails_file_field file_field],
    "text_area_fields" => %i[rails_text_area text_area],
    "time_zone_select_fields" => %i[rails_time_zone_select time_zone_select]
  }.freeze

  def setup
    super
    reload_field_modules
  end

  # Misma `source_location` = misma implementación. Es la aserción exacta: `owner` no sirve
  # porque el método se define sobre `Bali::FormBuilder` en cualquiera de los dos casos.
  def test_the_aliases_resolve_to_rails_and_not_to_balis_own_override
    MODULES.each_value do |saved_name, rails_name|
      assert_equal(
        ActionView::Helpers::FormBuilder.instance_method(rails_name).source_location,
        Bali::FormBuilder.instance_method(saved_name).source_location,
        "#{saved_name} tiene que ser el de Rails, no el override de Bali"
      )
    end
  end

  # Lo anterior fija la causa; esto fija el síntoma. Sin el arreglo cada una de estas tres
  # llamadas recursa hasta SystemStackError en vez de devolver markup.
  def test_the_fields_still_render_after_a_reload
    assert_html(builder.file_field(:cover_photo), 'input[type="file"]')
    assert_html(builder.text_area(:synopsis), "textarea")
    assert_html(builder.time_zone_select(:release_date), "select")
  end

  private

  # `load` re-ejecuta el archivo igual que lo hace Zeitwerk al recargar. Es idempotente con el
  # arreglo puesto —redefine los mismos métodos con el mismo cuerpo—, así que no ensucia a los
  # demás tests corran en el orden que corran.
  def reload_field_modules
    # `silence_warnings` sólo por las constantes que se re-inicializan al re-ejecutar el
    # archivo: es ruido del harness, no del código bajo prueba.
    Kernel.silence_warnings do
      MODULES.each_key do |file|
        load Bali::Engine.root.join("lib/bali/form_builder/#{file}.rb")
      end
    end
  end
end
