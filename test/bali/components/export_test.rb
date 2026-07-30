# frozen_string_literal: true

require "test_helper"

# El export nunca tuvo tests propios, que es por qué sobrevivió tanto tiempo exportando
# TODO desde un listado filtrado.
class BaliDataTableExportComponentTest < ComponentTestCase
  def test_the_href_carries_the_active_slice
    render_inline(export(params: { "q" => { "name_cont" => "dune" }, "group_by" => "status" }))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    assert_includes href, "q%5Bname_cont%5D=dune"
    assert_includes href, "group_by=status"
    assert_includes href, "format=csv"
  end

  def test_the_href_does_not_carry_the_page
    # Exportar SOLO la página 3 es peor que exportar de más: el usuario pidió "el listado".
    render_inline(export(params: { "page" => "3", "group_by" => "status" }))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    refute_includes href, "page="
    assert_includes href, "group_by=status"
  end

  def test_the_href_does_not_carry_the_one_shot_orders
    # EL test que justifica usar ToolbarHref en vez de `request.fullpath`: en el server
    # `clear_filters` corre `Rails.cache.delete(cache_key)`, así que un usuario parado en
    # `?clear_filters=true` se borraba los filtros guardados al clickear exportar.
    render_inline(export(params: { "clear_filters" => "true", "clear_search" => "true" }))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    refute_includes href, "clear_filters"
    refute_includes href, "clear_search"
  end

  def test_a_url_that_already_carries_a_query_string_is_not_corrupted
    # `?` a secas daba `/movies?scope=archived?format=csv`, que Rack lee como UN scope
    # corrupto y sin format.
    render_inline(export(url: "/movies?scope=archived"))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    assert_includes href, "scope=archived"
    assert_includes href, "format=csv"
    assert_equal 1, href.count("?")
  end

  def test_explicit_empty_params_is_the_opt_out
    render_inline(export(params: {}))

    assert_equal "/movies?format=csv", page.find("a", text: "CSV", visible: :all)["href"]
  end

  def test_no_request_context_does_not_blow_up
    # `params: nil` cae a `request_query_params`, que fuera de un request devuelve {}.
    render_inline(export(params: nil))

    assert_equal "/movies?format=csv", page.find("a", text: "CSV", visible: :all)["href"]
  end

  def test_every_link_opts_out_of_turbo_drive
    # Un CSV/XLSX no es una respuesta que Turbo Drive pueda renderizar: la visita se queda a
    # mitad de camino en vez de disparar la descarga.
    render_inline(export)

    assert_selector('a[data-turbo="false"]', count: 3, visible: :all)
  end

  def test_no_dead_rails_ujs_method_attribute
    render_inline(export)

    assert_no_selector("a[data-method]", visible: :all)
  end

  def test_the_method_keyword_is_gone
    error = assert_raises(ArgumentError) do
      Bali::DataTable::Export::Component.new(url: "/movies", method: :post)
    end
    assert_includes error.message, "method"
  end

  private

  def export(url: "/movies", params: {}, formats: %i[csv excel pdf])
    Bali::DataTable::Export::Component.new(url: url, params: params, formats: formats)
  end
end
