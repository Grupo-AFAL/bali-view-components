# frozen_string_literal: true

require "test_helper"

class BaliDataTableListingIdentityTest < ComponentTestCase
  def render_data_table(**options)
    render_inline(Bali::DataTable::Component.new(url: "/movies", **options)) do |dt|
      dt.with_column_selector { |cs| cs.with_column(index: 0, label: "Nombre") }
      dt.with_table { "<table><thead><tr><th>Nombre</th></tr></thead></table>".html_safe }
    end
  end

  def form(storage_id: nil)
    Bali::FilterForm.new(Movie.all, ActionController::Parameters.new, storage_id: storage_id)
  end

  def test_explicit_id_wins_over_the_forms_storage_id
    render_data_table(id: "listado_a", filter_form: form(storage_id: "listado_b"))

    assert_selector "div#listado_a.data-table-component"
    assert_selector "[data-column-selector-table-value='#listado_a table']"
    assert_selector "[data-column-selector-storage-key-value='bali:columns:listado_a']"
  end

  def test_the_id_falls_back_to_the_forms_storage_id
    render_data_table(filter_form: form(storage_id: "admin_movies"))

    assert_selector "div#admin_movies.data-table-component"
    assert_selector "[data-column-selector-table-value='#admin_movies table']"
    assert_selector "[data-column-selector-storage-key-value='bali:columns:admin_movies']"
  end

  def test_without_identity_the_id_is_random_and_column_persistence_turns_itself_off
    # Una llave que cambia en cada render no restaura NADA: apagarla es honesto, escribirla
    # sería un no-op silencioso.
    render_data_table

    assert_selector "[data-column-selector-storage-key-value='']"
    container_id = page.native.css("div.data-table-component").first["id"]
    assert_match(/\Adata-table-[0-9a-f]{8}\z/, container_id)
  end

  def test_two_listings_over_the_same_scope_no_longer_share_their_column_memory
    # /movies y /admin/movies filtran el MISMO scope base, así que el id viejo
    # (FilterForm#id = scope.cache_key) los volvía indistinguibles y compartían '#movies-table'.
    render_data_table(filter_form: form(storage_id: "movies"))
    assert_selector "[data-column-selector-storage-key-value='bali:columns:movies']"

    render_data_table(filter_form: form(storage_id: "admin_movies"))
    assert_selector "[data-column-selector-storage-key-value='bali:columns:admin_movies']"
  end

  def test_the_resolved_id_is_always_a_valid_css_identifier
    # FilterForm#id es scope.cache_key ('movies/query-abc'): la diagonal rompería el
    # querySelector del selector de columnas.
    render_data_table(id: "movies/query-abc")
    assert_selector "[data-column-selector-table-value='#movies-query-abc table']"

    # Un identificador CSS tampoco puede empezar con dígito: '#123 table' lanza SyntaxError.
    render_data_table(id: "123")
    assert_selector "[data-column-selector-table-value='#listing-123 table']"
  end

  def test_an_id_given_with_a_leading_hash_is_normalized_once
    render_data_table(id: "#movies-table")

    assert_selector "div#movies-table.data-table-component"
    assert_selector "[data-column-selector-table-value='#movies-table table']"
  end

  def test_the_documented_stream_target_is_the_id_the_component_renders
    # La receta de la guía de migración: `turbo_stream.replace ListingIdentity.for(form)`.
    # Turbo resuelve el target con getElementById, así que si esto se separa del id del
    # contenedor el stream se aplica sobre la nada — sin excepción y sin log.
    [ "movies", "admin/movies", "2026_reports", "#movies-table", "movies index" ].each do |storage_id|
      filter_form = form(storage_id: storage_id)
      render_data_table(filter_form: filter_form)

      rendered_id = page.native.css("div.data-table-component").first["id"]
      assert_equal rendered_id, Bali::DataTable::ListingIdentity.for(filter_form),
                   "ListingIdentity.for no describe el contenedor de storage_id=#{storage_id.inspect}"
    end
  end

  def test_listing_identity_also_sanitizes_a_raw_value
    assert_equal "admin-movies", Bali::DataTable::ListingIdentity.for("admin/movies")
    assert_equal "listing-123", Bali::DataTable::ListingIdentity.sanitize("123")
    assert_nil Bali::DataTable::ListingIdentity.sanitize("  ")
  end

  def test_an_explicit_persist_false_still_wins_over_a_stable_id
    render_inline(Bali::DataTable::Component.new(url: "/movies", id: "movies")) do |dt|
      dt.with_column_selector(persist: false) { |cs| cs.with_column(index: 0, label: "Nombre") }
      dt.with_table { "".html_safe }
    end

    assert_selector "[data-column-selector-storage-key-value='']"
  end
end
