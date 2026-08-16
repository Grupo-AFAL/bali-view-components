# frozen_string_literal: true

require "test_helper"

# Un form con las dos formas de recortar a la vez: el builder avanzado (que viaja anidado en
# `q[g][...]`) y un atributo plano. El round-trip del bulk tiene que reproducir las dos.
class BulkActionsRoundTripFilterForm < Bali::FilterForm
  filter_attribute :name, type: :text
  filter_attribute :status, type: :select, options: [ %w[Draft draft], %w[Done done] ]

  attribute :name_cont
  attribute :status_eq
  # Un date_range declarado como attribute: `result` lo aplica FUERA de Ransack. Desde #966
  # `active_filters` lo incluye igual (resuelto, `inicio..fin`); si volviera a perderlo, el
  # bulk actuaría sobre un superconjunto de lo que se ve.
  attribute :created_at, Bali::Types::DateRangeValue.new
end

# La otra forma de declarar un date_range: como filtro SIMPLE. Ese camino ya viaja dentro de
# `active_filters`, así que la re-emisión no tiene que agregarlo — y no puede agregarlo dos
# veces. Solo aquí existen los `presets:`.
class BulkActionsSimpleDateRangeFilterForm < Bali::FilterForm
  filter_attribute :created_at, type: :date, input: :date_range, simple: true, advanced: false,
                   presets: %i[today this_month]
end

class BaliBulkActionsComponentTest < ComponentTestCase
  def setup
    @component = Bali::BulkActions::Component.new
  end

  def test_rendering_renders_bulk_actions_component_with_base_class
    render_inline(@component)
    assert_selector("div.bulk-actions-component")
  end

  def test_rendering_renders_with_stimulus_controller
    render_inline(@component)
    assert_selector("[data-controller='bulk-actions']")
  end

  def test_rendering_accepts_custom_classes
    render_inline(Bali::BulkActions::Component.new(class: "custom-class"))
    assert_selector("div.bulk-actions-component.custom-class")
  end

  def test_items_renders_items_with_correct_data_attributes
    render_inline(@component) do |c|
      c.with_item(record_id: 42) { "Content" }
    end
    assert_selector("[data-record-id='42']")
    assert_selector("[data-bulk-actions-target='item']")
    assert_selector("[data-action='click->bulk-actions#toggle']")
  end

  def test_items_renders_items_with_base_class
    render_inline(@component) do |c|
      c.with_item(record_id: 1) { "Content" }
    end
    assert_selector(".bulk-actions-item", text: "Content")
  end

  def test_items_accepts_custom_classes_on_items
    render_inline(@component) do |c|
      c.with_item(record_id: 1, class: "custom-item-class") { "Content" }
    end
    assert_selector(".bulk-actions-item.custom-item-class")
  end

  # Un `selectAll` con `data-bulk-actions-group="<id>"` solo alcanza a los items que declaren
  # ese id. Sin `group:` no se emite atributo, y sin atributo el item entra en todos.
  def test_items_carry_no_group_by_default
    render_inline(@component) do |c|
      c.with_item(record_id: 1) { "Content" }
    end
    assert_no_selector("[data-bulk-actions-group]")
  end

  def test_items_declare_the_groups_they_belong_to
    render_inline(@component) do |c|
      c.with_item(record_id: 1, group: "norte") { "Content" }
      c.with_item(record_id: 2, group: %w[norte tijuana]) { "Content" }
    end
    assert_selector("[data-record-id='1'][data-bulk-actions-group='norte']")
    assert_selector("[data-record-id='2'][data-bulk-actions-group='norte tijuana']")
  end

  def test_items_renders_multiple_items
    render_inline(@component) do |c|
      c.with_item(record_id: 1) { "Item 1" }
      c.with_item(record_id: 2) { "Item 2" }
      c.with_item(record_id: 3) { "Item 3" }
    end
    assert_selector(".bulk-actions-item", count: 3)
    assert_selector("[data-record-id='1']")
    assert_selector("[data-record-id='2']")
    assert_selector("[data-record-id='3']")
  end

  def test_actions_renders_actions_container_with_stimulus_target
    render_inline(@component) do |c|
      c.with_action(label: "Update", href: "/update")
    end
    assert_selector("[data-bulk-actions-target='actionsContainer']")
  end

  def test_actions_renders_selected_count_with_stimulus_target
    render_inline(@component) do |c|
      c.with_action(label: "Update", href: "/update")
    end
    assert_selector("[data-bulk-actions-target='selectedCount']", text: "0")
  end

  def test_actions_hides_actions_container_initially
    render_inline(@component) do |c|
      c.with_action(label: "Archive", href: "/archive")
    end
    assert_selector(".hidden[data-bulk-actions-target='actionsContainer']")
  end

  def test_actions_with_post_method_default_renders_as_a_form
    render_inline(@component) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector("form[action='/delete']")
    assert_button("Delete")
    assert_selector("input[name='selected_ids'][data-bulk-actions-target='bulkAction']", visible: false)
  end

  def test_actions_with_post_method_default_applies_variant_classes_to_submit_button
    render_inline(@component) do |c|
      c.with_action(label: "Delete", href: "/delete", variant: :error)
    end
    assert_selector("input.btn.btn-sm.btn-error")
  end

  def test_actions_with_delete_method_renders_as_a_form_with_hidden_method_field
    render_inline(@component) do |c|
      c.with_action(label: "Remove", href: "/remove", method: :delete)
    end
    assert_selector("form[action='/remove']")
    assert_selector("input[name='_method'][value='delete']", visible: false)
    assert_button("Remove")
  end

  def test_actions_with_get_method_renders_as_a_link
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get)
    end
    assert_link("Export", href: "/export")
    assert_selector("a[data-bulk-actions-target='bulkAction']")
  end

  def test_actions_with_get_method_applies_button_styling_to_link
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get, variant: :info)
    end
    assert_selector("a.btn.btn-info")
  end

  def test_actions_renders_multiple_actions
    render_inline(@component) do |c|
      c.with_action(label: "Archive", href: "/archive", variant: :info)
      c.with_action(label: "Delete", href: "/delete", variant: :error)
    end
    assert_button("Archive")
    assert_button("Delete")
  end

  def test_toolbar_variant_renders_the_contextual_bar_instead_of_the_floating_one
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector(".hidden.mb-4[data-bulk-actions-target='actionsContainer']")
    assert_no_selector(".fixed[data-bulk-actions-target='actionsContainer']")
  end

  def test_toolbar_variant_renders_a_clear_button_wired_to_the_controller
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector("button[data-action='bulk-actions#clear']", visible: :all)
    assert_no_selector("a[data-action='bulk-actions#clear']", visible: :all)
  end

  def test_toolbar_variant_renders_both_plural_labels_with_the_singular_hidden
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector("[data-bulk-actions-target='selectedLabelOne'].hidden", visible: :all)
    assert_selector("[data-bulk-actions-target='selectedLabelOther']", visible: :all)
    assert_selector("[data-bulk-actions-target='selectedCount']", text: "0", visible: :all)
  end

  def test_unknown_variant_falls_back_to_floating
    render_inline(Bali::BulkActions::Component.new(variant: :sidebar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector(".fixed[data-bulk-actions-target='actionsContainer']")
  end

  def test_standalone_false_does_not_emit_its_own_stimulus_controller
    # Dos controladores `bulk-actions` anidados se reparten los targets: la barra dejaría
    # de ver las filas y el contador quedaría en 0 SIN error.
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false))
    assert_selector("div.bulk-actions-component")
    assert_no_selector("[data-controller='bulk-actions']")
  end

  def test_custom_data_attributes_survive_in_both_modes
    render_inline(Bali::BulkActions::Component.new(data: { foo: "bar" }))
    assert_selector("[data-foo='bar'][data-controller='bulk-actions']")

    render_inline(Bali::BulkActions::Component.new(standalone: false, data: { foo: "bar" }))
    assert_selector("[data-foo='bar']")
  end

  def test_combined_items_and_actions_renders_both_items_and_actions_together
    render_inline(@component) do |c|
      c.with_action(label: "Bulk Update", href: "/bulk_update")
      c.with_item(record_id: 1) { "Item 1" }
      c.with_item(record_id: 2) { "Item 2" }
    end
    assert_selector(".bulk-actions-component")
    assert_selector(".bulk-actions-item", count: 2)
    assert_button("Bulk Update")
  end

  # --- Control por acción (#724) ---------------------------------------------------------

  def test_a_control_renders_inside_the_actions_own_form_before_the_submit
    render_inline(@component) do |c|
      c.with_action(label: "Assign", href: "/assign") do |action|
        action.with_control do
          %(<select name="driver_id" class="select"><option value="1">Ana</option></select>).html_safe
        end
      end
    end

    assert_selector("form[action='/assign'] select[name='driver_id']", visible: :all)
    # El orden importa: el submit va último para que el control quede antes en el tab order.
    inputs = page.find("form[action='/assign']").all("select, input", visible: :all).map { |n| n[:name] }
    assert_equal(%w[selected_ids driver_id commit], inputs.compact.reject(&:empty?))
  end

  def test_a_control_on_a_get_action_raises_instead_of_dropping_the_value
    error = assert_raises(ArgumentError) do
      render_inline(@component) do |c|
        c.with_action(label: "Export", href: "/export", method: :get) do |action|
          action.with_control { %(<input type="text" name="format">).html_safe }
        end
      end
    end

    assert_match(/with_control/, error.message)
    assert_match(/method: :get/, error.message)
    assert_match(/Export/, error.message)
  end

  def test_a_get_action_without_a_control_still_renders_as_a_link
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get)
    end
    assert_link("Export", href: "/export")
  end

  # Cada acción es su propio form y todas emiten el mismo campo: con el id derivado del name,
  # una barra de tres acciones repetía `id="selected_ids"` tres veces en el documento.
  def test_the_selected_ids_field_carries_no_id_so_several_actions_can_coexist
    render_inline(@component) do |c|
      c.with_action(label: "Archive", href: "/archive")
      c.with_action(label: "Delete", href: "/delete")
    end

    fields = page.all("input[name='selected_ids']", visible: :all)
    assert_equal(2, fields.size)
    assert(fields.none? { |field| field[:id].present? }, "el hidden de ids no debe llevar id")
  end

  # La guía promete que `data: { turbo_confirm: }` en la acción pasa por el diálogo de Bali:
  # eso solo funciona si el atributo aterriza en el `<form>`, que es donde Turbo lo lee.
  def test_data_attributes_reach_the_form_so_turbo_confirm_works
    render_inline(@component) do |c|
      c.with_action(label: "Borrar", href: "/borrar", data: { turbo_confirm: "¿Seguro?" })
    end

    assert_selector("form[action='/borrar'][data-turbo-confirm='¿Seguro?']", visible: :all)
  end

  # --- target: (#724) --------------------------------------------------------------------

  def test_target_reaches_the_form_of_a_post_action
    render_inline(@component) do |c|
      c.with_action(label: "Print", href: "/print", target: "_blank")
    end
    assert_selector("form[action='/print'][target='_blank']", visible: :all)
  end

  # `form_with` solo respeta un puñado de opciones sueltas: un `target:` por **options se
  # perdía sin avisar, que es la razón de que sea opción de primera clase.
  def test_target_is_not_swallowed_the_way_a_bare_passthrough_was
    render_inline(@component) do |c|
      c.with_action(label: "Print", href: "/print")
    end
    assert_no_selector("form[target]", visible: :all)
  end

  def test_target_reaches_the_anchor_of_a_get_action
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get, target: "_blank")
    end
    assert_selector("a[href='/export'][target='_blank']")
  end

  # La fila contextual REEMPLAZA a la toolbar del DataTable en su mismo hueco: si miden
  # distinto, seleccionar una fila empuja el listado. Antes pasaba (18px: `py-2` + `border`).
  def test_the_toolbar_row_declares_the_same_minimum_height_as_the_datatable_toolbar
    assert_includes(Bali::DataTable::Component::TOOLBAR_CLASSES,
                    Bali::BulkActions::Component::TOOLBAR_MIN_HEIGHT)

    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end

    bar = page.find("[data-bulk-actions-target='actionsContainer'] > div")
    assert_includes(bar[:class], Bali::BulkActions::Component::TOOLBAR_MIN_HEIGHT)
  end

  # La barra mide lo mismo que la toolbar (32px), así que un botón `sm` —que mide EXACTAMENTE
  # eso— queda a ras del tinte y se ve apretado. `xs` deja 4px de aire sin mover el alto.
  # La flotante no vive dentro de una superficie de alto fijo y conserva `sm`.
  def test_the_toolbar_row_sizes_its_actions_below_the_bar_height
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end
    assert_selector("input.btn.btn-xs[value='Borrar']")
    assert_no_selector(".btn-sm")

    render_inline(Bali::BulkActions::Component.new) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end
    assert_selector("input.btn.btn-sm[value='Borrar']")
  end

  def test_an_explicit_action_size_wins_over_the_one_the_bar_injects
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar", size: :lg)
    end
    assert_selector("input.btn.btn-lg[value='Borrar']")
  end

  # El contorno va con `ring` (box-shadow) y sin padding vertical justamente porque un
  # `border`/`py-*` sí ocupan layout y devolverían el salto.
  def test_the_toolbar_row_outline_costs_no_vertical_space
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end

    classes = page.find("[data-bulk-actions-target='actionsContainer'] > div")[:class]
    assert_includes(classes, "ring-1")
    refute_match(/\bborder\b/, classes)
    refute_match(/\bpy-\d/, classes)
  end
end

# El contrato "actuar sobre los N filtrados" (#724): qué se pinta, qué viaja en el POST y que
# lo que viaja reproduce el MISMO scope que el listado.
class BaliBulkActionsSelectAllFilteredTest < ComponentTestCase
  FILTER_PAIRS = [
    [ "q[g][0][m]", "or" ],
    [ "q[g][0][name_cont]", "Iron" ],
    [ "q[status_eq]", "draft" ]
  ].freeze

  def bar(total_count: 120, filter_params: FILTER_PAIRS, **options)
    Bali::BulkActions::Component.new(total_count: total_count, filter_params: filter_params,
                                     **options)
  end

  # --- Lo que se pinta -------------------------------------------------------------------

  def test_without_a_total_count_nothing_of_the_mode_exists
    render_inline(Bali::BulkActions::Component.new(filter_params: FILTER_PAIRS)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end

    assert_no_selector("[data-bulk-actions-target='selectAllOffer']", visible: :all)
    assert_no_selector("input[name='select_all_filtered']", visible: :all)
    # Los filtros tampoco: sin flag que los active, solo serían ruido en el POST.
    assert_no_selector("input[name='q[status_eq]']", visible: :all)
  end

  def test_the_offer_and_the_notice_carry_n_from_the_server
    render_inline(bar) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    offer = page.find("[data-bulk-actions-target='selectAllOffer']", visible: :all)
    assert_equal("120", offer["data-total-count"])
    assert_selector("[data-bulk-actions-target='selectAllOffer'] button", text: "Select all 120 results",
                    visible: :all)
    assert_selector("[data-bulk-actions-target='selectAllNotice']",
                    text: "All 120 results are selected", visible: :all)
  end

  # Ambos arrancan ocultos: la oferta solo aplica con la página entera marcada, y el aviso
  # solo dentro del modo. El JS decide; el servidor no puede saber ninguna de las dos cosas.
  def test_the_offer_and_the_notice_start_hidden
    render_inline(bar) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    assert_selector("[data-bulk-actions-target='selectAllOffer'].hidden", visible: :all)
    assert_selector("[data-bulk-actions-target='selectAllNotice'].hidden", visible: :all)
  end

  def test_the_offer_is_a_button_because_it_changes_state_instead_of_navigating
    render_inline(bar) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    assert_selector("button[data-action='bulk-actions#selectAllFiltered']", visible: :all)
    assert_no_selector("a[data-action='bulk-actions#selectAllFiltered']", visible: :all)
  end

  # --- Lo que viaja en el POST -----------------------------------------------------------

  def test_every_action_form_carries_the_flag_off_and_the_active_filters
    render_inline(bar) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
      c.with_action(label: "Archivar", href: "/archivar")
    end

    flags = page.all("input[name='select_all_filtered']", visible: :all)
    assert_equal(2, flags.size)
    assert(flags.all? { |flag| flag.value == "false" }, "el flag arranca apagado")
    assert(flags.all? { |flag| flag[:id].blank? }, "el flag no debe llevar id: se repite por form")
    assert_selector("[data-bulk-actions-target='selectAllFilteredField']", count: 2, visible: :all)

    FILTER_PAIRS.each do |name, value|
      assert_selector("form[action='/borrar'] input[name='#{name}'][value='#{value}']", visible: :all)
      assert_selector("form[action='/archivar'] input[name='#{name}'][value='#{value}']", visible: :all)
    end
  end

  # Una acción GET no tiene hidden fields, así que los filtros viajan en su href — y los que
  # el href ya trajera se descartan: el estado vigente del listado es el que manda.
  def test_a_get_action_carries_the_filters_in_its_href
    render_inline(bar) do |c|
      c.with_action(label: "Exportar", href: "/exportar?format=csv&q%5Bname_cont%5D=viejo",
                    method: :get)
    end

    query = Rack::Utils.parse_nested_query(URI.parse(page.find("a")[:href]).query)
    assert_equal("csv", query["format"])
    assert_equal("Iron", query.dig("q", "g", "0", "name_cont"))
    assert_equal("draft", query.dig("q", "status_eq"))
  end

  # --- El round-trip: lo que viaja reproduce el listado ------------------------------------

  def test_the_filters_a_data_table_emits_rebuild_the_very_same_scope
    tenant = Tenant.create(name: "Round trip")
    iron_1 = tenant.movies.create(name: "Iron man 1", status: 0)
    iron_2 = tenant.movies.create(name: "Iron man 2", status: 0)
    tenant.movies.create(name: "Snatch", status: 0)

    listing_params = ActionController::Parameters.new(
      q: { g: { "0" => { m: "or", name_cont: "Iron" } }, status_eq: "draft" }
    )
    listing = BulkActionsRoundTripFilterForm.new(tenant.movies, listing_params)
    assert_equal([ iron_1.id, iron_2.id ].sort, listing.result.pluck(:id).sort)

    render_inline(
      Bali::BulkActions::Component.new(
        total_count: listing.result.count,
        filter_params: Bali::Filters::ActiveFilterParams.for_filter_form(listing)
      )
    ) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    # Exactamente lo que el navegador postearía de ese form.
    posted = Rack::Utils.parse_nested_query(
      page.all("form[action='/borrar'] input[type=hidden]", visible: :all)
          .reject { |input| %w[authenticity_token selected_ids].include?(input[:name]) }
          .map { |input| "#{CGI.escape(input[:name])}=#{CGI.escape(input.value.to_s)}" }
          .join("&")
    )
    assert_equal("false", posted["select_all_filtered"])

    rebuilt = BulkActionsRoundTripFilterForm.new(
      tenant.movies, ActionController::Parameters.new(posted)
    )
    assert_equal(listing.result.pluck(:id).sort, rebuilt.result.pluck(:id).sort)
  end

  # Un `date_range` declarado como attribute NO pasa por Ransack: `result` lo aplica aparte.
  # Antes de #966 `active_filters` lo excluía por construcción y la re-emisión lo perdía: el
  # listado mostraba 1 registro y el servidor re-derivaba 2 — el bulk actuando sobre un
  # SUPERCONJUNTO de lo que se ve, que a escala es un destroy_all tocando justo lo que el
  # filtro de fecha excluía.
  def test_a_date_range_filter_survives_the_round_trip
    tenant = Tenant.create(name: "Date range")
    reciente = tenant.movies.create(name: "Iron man 3", status: 0)
    reciente.update_column(:created_at, Time.zone.parse("2026-03-15 12:00"))
    vieja = tenant.movies.create(name: "Iron man 1", status: 0)
    vieja.update_column(:created_at, Time.zone.parse("2020-01-05 12:00"))

    listing_params = ActionController::Parameters.new(
      q: { name_cont: "Iron", created_at: "2026-01-01..2026-12-31" }
    )
    listing = BulkActionsRoundTripFilterForm.new(tenant.movies, listing_params)
    assert_equal([ reciente.id ], listing.result.pluck(:id))

    pairs = Bali::Filters::ActiveFilterParams.for_filter_form(listing)
    posted = Rack::Utils.parse_nested_query(
      pairs.map { |name, value| "#{CGI.escape(name.to_s)}=#{CGI.escape(value.to_s)}" }.join("&")
    )
    rebuilt = BulkActionsRoundTripFilterForm.new(
      tenant.movies, ActionController::Parameters.new(posted)
    )

    assert_equal(listing.result.pluck(:id), rebuilt.result.pluck(:id),
                 "los pares re-emitidos tienen que reproducir el recorte por fecha")
  end

  # Un date_range declarado como filtro SIMPLE viaja dentro de `active_filters` con el valor
  # CRUDO. La re-emisión no puede agregarlo otra vez: dos hidden con el mismo `name` y el
  # servidor se queda con uno, en silencio. Hoy eso se sostiene porque los dos caminos de
  # `active_filters` (attribute resuelto y simple crudo) colisionan en la MISMA clave y el
  # simple gana — si esa forma cambia, este test es el que avisa.
  def test_a_simple_date_range_is_emitted_exactly_once
    listing = BulkActionsSimpleDateRangeFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { created_at: "this_month" })
    )

    pairs = Bali::Filters::ActiveFilterParams.for_filter_form(listing)
    created_at = pairs.select { |name, _| name == "q[created_at]" }

    assert_equal(1, created_at.size, "un date_range simple se emite UNA vez: #{pairs.inspect}")
    # Y viaja como TOKEN, no como el rango ya resuelto: este camino lo sirve `active_filters`
    # con el valor crudo, así que el servidor lo vuelve a resolver contra su propio reloj.
    assert_equal("this_month", created_at.first.last)
  end

  # --- El DataTable lo cablea solo --------------------------------------------------------

  def test_a_data_table_feeds_n_from_its_pagy_and_the_filters_from_its_filter_form
    filter_form = BulkActionsRoundTripFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { name_cont: "Iron" })
    )

    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: filter_form,
                                     pagy: Pagy::Offset.new(count: 47, page: 1, limit: 10))
    ) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Borrar", href: "/borrar") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_equal("47", page.find("[data-bulk-actions-target='selectAllOffer']",
                                 visible: :all)["data-total-count"])
    assert_selector("form[action='/borrar'] input[name='q[name_cont]'][value='Iron']", visible: :all)
  end

  # Paginación countless: `count` es nil por diseño, así que no hay N que ofrecer. Ofrecer
  # "seleccionar los resultados" sin saber cuántos son es prometer algo que no se puede medir.
  def test_a_countless_pagy_offers_nothing
    render_inline(
      Bali::DataTable::Component.new(url: "/movies", pagy: Pagy::Offset.new(count: 0, page: 1, limit: 10))
    ) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Borrar", href: "/borrar") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector("[data-bulk-actions-target='selectAllOffer']", visible: :all)
    assert_no_selector("input[name='select_all_filtered']", visible: :all)
  end

  # Un hash anidado es la otra forma de escribir los mismos pares.
  def test_filter_params_accepts_a_nested_hash
    render_inline(
      Bali::BulkActions::Component.new(total_count: 5, filter_params: { q: { name_cont: "Iron" } })
    ) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    assert_selector("input[name='q[name_cont]'][value='Iron']", visible: :all)
  end

  # Una acción montada a mano, fuera de la barra, normaliza igual: `Array(hash)` la dejaba
  # como UN hidden llamado `q` con el `to_s` del hash adentro — un POST que parece bien
  # formado y no filtra nada.
  def test_an_action_mounted_on_its_own_normalizes_a_nested_hash_too
    render_inline(
      Bali::BulkActions::Action::Component.new(
        label: "Borrar", href: "/borrar",
        select_all_filtered: true, filter_params: { q: { name_cont: "Iron" } }
      )
    )

    assert_selector("input[name='q[name_cont]'][value='Iron']", visible: :all)
    assert_no_selector("input[name='q']", visible: :all)
  end

  def test_a_filter_params_shape_that_cannot_be_serialized_says_so
    error = assert_raises(ArgumentError) do
      Bali::BulkActions::Component.new(total_count: 5, filter_params: "q[name_cont]=Iron")
    end

    assert_match(/filter_params/, error.message)
    assert_match(/nested hash/, error.message)
  end
end
