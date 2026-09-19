# frozen_string_literal: true

require "test_helper"

# Three helpers keep Rails' method under a `rails_*` name so they can publish their own under the
# canonical one. They used to be kept with `alias`, which captures whatever the name resolves to AT
# THAT MOMENT — and those files are re-executed on every code reload, when Bali's module is ALREADY
# included. The alias then pointed at Bali's override and the helper called itself:
# `SystemStackError` on every file field, every text area and every time zone select, from the first
# reload until the server was restarted (#840).
#
# The suite started cold and never saw it. This test reloads the files on purpose.
class BaliFormBuilderRailsAliasesSurviveAReloadTest < FormBuilderTestCase
  # file => [saved name, Rails' name]
  MODULES = {
    "file_fields" => %i[rails_file_field file_field],
    "text_area_fields" => %i[rails_text_area text_area],
    "time_zone_select_fields" => %i[rails_time_zone_select time_zone_select]
  }.freeze

  def setup
    super
    reload_field_modules
  end

  # Same `source_location` = same implementation. That is the exact assertion: `owner` is no use
  # because the method is defined on `Bali::FormBuilder` either way.
  def test_the_aliases_resolve_to_rails_and_not_to_balis_own_override
    MODULES.each_value do |saved_name, rails_name|
      assert_equal(
        ActionView::Helpers::FormBuilder.instance_method(rails_name).source_location,
        Bali::FormBuilder.instance_method(saved_name).source_location,
        "#{saved_name} tiene que ser el de Rails, no el override de Bali"
      )
    end
  end

  # The above pins the cause; this pins the symptom. Without the fix each of these three calls
  # recurses into SystemStackError instead of returning markup.
  def test_the_fields_still_render_after_a_reload
    assert_html(builder.file_field(:cover_photo), 'input[type="file"]')
    assert_html(builder.text_area(:synopsis), "textarea")
    assert_html(builder.time_zone_select(:release_date), "select")
  end

  private

  # `load` re-executes the file the same way Zeitwerk does on a reload. It is idempotent with the fix
  # in place —it redefines the same methods with the same bodies— so it does not dirty the other
  # tests whatever order they run in.
  def reload_field_modules
    # `silence_warnings` only for the constants that get re-initialised when the file re-executes:
    # that is noise from the harness, not from the code under test.
    Kernel.silence_warnings do
      MODULES.each_key do |file|
        load Bali::Engine.root.join("lib/bali/form_builder/#{file}.rb")
      end
    end
  end
end
