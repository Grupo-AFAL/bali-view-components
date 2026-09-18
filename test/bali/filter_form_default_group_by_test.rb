# frozen_string_literal: true

require "test_helper"

# #1156, mitad 1. `filter_attribute default:` abre un listado sobre una pregunta; la
# agrupación no tenía equivalente, así que el anfitrión fijaba `@group_by` después de `super`
# y reimplementaba a mano la regla «nadie ha dicho nada», leyendo la caché de persistencia.
#
# El default de agrupación NO viaja por la URL (el camino que `DefaultFilters` eligió para los
# filtros): `redirect_to_default_filters` se apaga entero con la persistencia encendida
# (filterable.rb:104) y un redirect que escriba `?group_by=` marcaría el param como PEDIDO,
# pisando en la caché el «sin agrupación» que el usuario eligió. Vive dentro del form, como el
# último escalón de la resolución:
#
#   URL > payload de una vista guardada > elección guardada en la caché > `default:` > nada
class BaliFilterFormDefaultGroupByTest < ActiveSupport::TestCase
  class DefaultGroupedMovieFilterForm < Bali::FilterForm
    group_by_attribute :genre, label: "Género"
    group_by_attribute :status, default: true

    attribute :genre_eq
  end

  def group_params(**extra)
    ActionController::Parameters.new({ q: ActionController::Parameters.new({}) }.merge(extra))
  end

  def form(**extra)
    DefaultGroupedMovieFilterForm.new(Movie.all, group_params(**extra))
  end

  # --- El default aplica cuando nadie dijo nada ---

  def test_the_declared_default_groups_the_listing_when_no_param_arrives
    opened = form

    assert_equal(:status, opened.group_by)
    assert_equal(:status, opened.group_by_applied)
    assert(opened.group_by_active?)
  end

  def test_the_default_is_readable_as_such
    assert_equal(:status, DefaultGroupedMovieFilterForm.new(Movie.all, group_params).default_group_by)
    assert(form.group_by_from_default?)
    refute(form(group_by: "status").group_by_from_default?,
           "elegir explícitamente lo mismo que el default es una ELECCIÓN, no un default")
  end

  # --- La URL gana siempre ---

  def test_an_explicit_group_by_in_the_url_beats_the_default
    assert_equal(:genre, form(group_by: "genre").group_by)
    refute(form(group_by: "genre").group_by_from_default?)
  end

  def test_an_empty_group_by_in_the_url_turns_the_grouping_off
    # `?group_by=` es «sin agrupación» (el item del control, group_by_control/component.rb:104).
    # Sin esta distinción el usuario no puede desagrupar un listado con default.
    ungrouped = form(group_by: "")

    assert_nil(ungrouped.group_by)
    refute(ungrouped.group_by_active?)
  end

  def test_an_undeclared_group_by_value_also_counts_as_the_url_speaking
    assert_nil(form(group_by: "none").group_by)
  end

  # Cómo se DICE "sin agrupación" en la URL cambia con el default, porque un param vacío no
  # sobrevive al `sort_link` de Ransack ni a los hidden fields: medido con el server levantado,
  # `?group_by=` desaparece del href de ordenar y `?group_by=genre` no.
  def test_no_grouping_travels_by_name_only_where_a_default_needs_it
    assert_equal("none", form.no_grouping_value)
    assert_equal("", Bali::FilterForm.new(Movie.all, group_params,
                                          group_by_attributes: %i[genre status]).no_grouping_value)
  end

  def test_the_named_no_grouping_value_survives_a_round_trip
    assert_nil(form(group_by: Bali::FilterForm::GroupByConfiguration::NO_GROUPING_VALUE).group_by)
  end

  # --- Suspensión: el default es estado como cualquier otro ---

  def test_the_default_is_suspended_outside_a_grouping_mode
    suspended = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params, group_by_modes: [ :table ], display_mode: :grid
    )

    assert_equal(:status, suspended.group_by)
    assert_nil(suspended.group_by_applied)
    assert(suspended.group_by_suspended?)
  end

  # El viaje real tabla↔tarjetas con la agrupación APAGADA: en tarjetas no se aplica ni se ve
  # el control, pero el "sin agrupación" tiene que seguir viajando o volver a la tabla la
  # reagrupa con el default.
  def test_an_explicit_no_grouping_keeps_travelling_while_suspended
    suspended = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(group_by: "none"), group_by_modes: [ :table ], display_mode: :grid
    )

    assert_nil(suspended.group_by)
    assert_equal("none", suspended.group_by_preserved_value)
  end

  # Los tres valores que puede tomar lo que se preserva, en un solo lugar: es lo que alimenta
  # al hidden field del DataTable y al payload de una vista guardada.
  def test_what_travels_has_three_answers_and_not_two
    assert_nil(form.group_by_preserved_value, "un default se re-deriva: arrastrarlo lo vuelve elección")
    assert_equal("genre", form(group_by: "genre").group_by_preserved_value)
    assert_equal("none", form(group_by: "none").group_by_preserved_value)
  end

  # --- Declaración ---

  def test_the_constructor_form_accepts_the_default_too
    instance = Bali::FilterForm.new(
      Movie.all, group_params,
      group_by_attributes: [ :genre, { attribute: :status, default: true } ]
    )

    assert_equal(:status, instance.group_by)
  end

  def test_two_different_defaults_raise_when_the_form_is_built
    contradiction = Class.new(Bali::FilterForm) do
      group_by_attribute :genre, default: true
      group_by_attribute :status, default: true
    end

    error = assert_raises(ArgumentError) { contradiction.new(Movie.all, group_params) }
    assert_match(/genre/, error.message)
    assert_match(/status/, error.message)
  end

  def test_a_callable_default_raises_instead_of_being_silently_truthy
    callable = Class.new(Bali::FilterForm) do
      group_by_attribute :status, default: -> { true }
    end

    error = assert_raises(ArgumentError) { callable.new(Movie.all, group_params) }
    assert_match(/default:/, error.message)
  end

  def test_a_subclass_inherits_the_declared_default
    subclass = Class.new(DefaultGroupedMovieFilterForm)

    assert_equal(:status, subclass.new(Movie.all, group_params).group_by)
  end

  # --- Vistas guardadas ---

  class FakeSavedViewsStore
    SavedView = Struct.new(:id, :name, :payload, keyword_init: true)

    def initialize(views = []) = @views = views
    def list = @views
    def find(id) = @views.find { |view| view.id.to_s == id.to_s }
    def save(name:, payload:) = SavedView.new(id: 1, name: name, payload: payload)
    def delete(id) = @views.reject! { |view| view.id.to_s == id.to_s }
  end

  def store_with_view(payload)
    FakeSavedViewsStore.new([ FakeSavedViewsStore::SavedView.new(id: 1, name: "Mi vista", payload: payload) ])
  end

  def test_a_saved_view_that_records_a_grouping_beats_the_default
    applied = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"),
      saved_views_store: store_with_view({ "group_by" => "genre" })
    )

    assert_equal(:genre, applied.group_by)
    refute(applied.group_by_from_default?)
  end

  def test_a_default_only_grouping_stays_out_of_the_saved_view_payload
    # Si entrara, TODA vista guardada sin `group_by` se vería «modificada» contra un listado
    # que nadie tocó (saved_views_configuration.rb:126 + comparable_view_state): un default no
    # es una elección del usuario.
    payload = form.current_view_payload

    refute(payload.key?("group_by"), payload.inspect)
    assert_equal("status", form(group_by: "status").current_view_payload["group_by"])
  end

  # EL ROUND-TRIP QUE FALTABA. Una vista guardada mientras el usuario tenía la agrupación
  # APAGADA volvía a abrirse AGRUPADA: el payload salía `{"attributes"=>{}}` —el nil se
  # compactaba— y al aplicarla el default no encontraba a nadie que hubiera hablado. Es la
  # misma ambigüedad nil-vs-ausente que `NO_GROUPING_VALUE` resuelve en la URL, y se cura
  # igual: la vista tiene que poder DECIR «sin agrupar».
  def test_a_view_saved_while_ungrouped_reopens_ungrouped
    payload = form(group_by: Bali::FilterForm::GroupByConfiguration::NO_GROUPING_VALUE)
              .current_view_payload

    assert_equal("none", payload["group_by"], payload.inspect)

    reopened = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"), saved_views_store: store_with_view(payload)
    )

    assert_nil(reopened.group_by, "la vista dijo «sin agrupar»: el default no puede resucitar")
    refute(reopened.group_by_from_default?)
  end

  # La otra mitad, y la razón por la que el silencio NO puede significar «sin agrupación»:
  # una vista guardada antes de que el default existiera —o en un listado que no lo declara—
  # llega SIN la llave, y ahí el default sigue siendo quien habla.
  def test_a_view_that_says_nothing_about_grouping_still_takes_the_default
    applied = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"),
      saved_views_store: store_with_view({ "attributes" => { "genre_eq" => "Action" } })
    )

    assert_equal(:status, applied.group_by)
    assert(applied.group_by_from_default?)
  end

  # Y reabierta no se ve «modificada»: el payload que el form vuelve a componer es el mismo
  # que se guardó, sentinel incluido.
  def test_an_ungrouped_view_is_recognised_as_active_when_reopened
    payload = form(group_by: "none").current_view_payload
    view = FakeSavedViewsStore::SavedView.new(id: 1, name: "Sin agrupar", payload: payload)
    reopened = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"), saved_views_store: FakeSavedViewsStore.new([ view ])
    )

    assert(reopened.view_matches_current_state?(view))
  end

  # Sin default no hay nada que suprimir, así que el payload no cambia ni un byte: «sin
  # agrupación» sigue siendo la ausencia de la llave, como antes de #1156.
  def test_a_listing_without_a_default_keeps_the_payload_it_always_had
    plain = Bali::FilterForm.new(Movie.all, group_params(group_by: ""),
                                 group_by_attributes: %i[genre status])

    refute(plain.current_view_payload.key?("group_by"), plain.current_view_payload.inspect)
  end

  def test_a_view_saved_under_the_default_is_still_recognised_as_active
    view = FakeSavedViewsStore::SavedView.new(id: 1, name: "Mi vista",
                                              payload: { "attributes" => { "genre_eq" => "Action" } })
    applied = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(q: ActionController::Parameters.new(genre_eq: "Action")),
      saved_views_store: FakeSavedViewsStore.new([ view ])
    )

    assert(applied.view_matches_current_state?(view))
  end
end

class BaliFilterFormDefaultGroupByPersistenceTest < ActiveSupport::TestCase
  class PersistedDefaultGroupedFilterForm < Bali::FilterForm
    group_by_attribute :genre
    group_by_attribute :status, default: true

    attribute :genre_eq
  end

  def setup
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  def teardown
    Rails.cache = @original_cache
  end

  def cache_key
    "#{PersistedDefaultGroupedFilterForm.name.tableize};;movies"
  end

  def persisted_form(**extra)
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(extra),
      storage_id: "movies", persist_enabled: true
    )
  end

  def test_a_grouping_stored_in_the_cache_beats_the_default
    Rails.cache.write(cache_key, { attributes: {}, group_by: "genre", group_by_chosen: true })

    assert_equal(:genre, persisted_form.group_by)
  end

  def test_an_explicit_no_grouping_stored_in_the_cache_is_not_resurrected_by_the_default
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: ""),
      storage_id: "movies", persist_enabled: true
    )

    assert_nil(persisted_form.group_by, "el usuario desagrupó: el default no puede resucitar")
  end

  def test_a_cache_written_before_the_default_existed_does_not_kill_it
    # v3.4.0 escribe `group_by: nil` en CADA submit de filtros (filter_form.rb:688), así que
    # cualquier listado con persistencia ya tiene esa llave grabada. Si la sola presencia de
    # la llave apagara el default, el feature nacería muerto en producción.
    Rails.cache.write(cache_key, { attributes: { "genre_eq" => "Action" }, group_by: nil })

    assert_equal(:status, persisted_form.group_by)
  end

  def test_the_default_is_never_written_into_the_cache
    # Derivado, no persistido: cambiar el default en el código tiene que cambiar lo que ven
    # los usuarios que ya visitaron el listado.
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "Action" }),
      storage_id: "movies"
    )

    stored = Rails.cache.read(cache_key)
    assert_nil(stored[:group_by])
    refute(stored[:group_by_chosen])
  end

  def test_a_chosen_grouping_is_still_written_into_the_cache
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "Action" }, group_by: "genre"),
      storage_id: "movies"
    )

    stored = Rails.cache.read(cache_key)
    assert_equal("genre", stored[:group_by].to_s)
    assert(stored[:group_by_chosen])
  end
end
