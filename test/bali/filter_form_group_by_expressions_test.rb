# frozen_string_literal: true

require "test_helper"

# #1102. `group_by_attribute` solo aceptaba columnas reales: un `ransacker` o un camino de
# asociación —los dos que Ransack ordena sin chistar— llegaban al SQL como identificadores
# pelados y reventaban ahí. Estos tests fijan las dos mitades de la corrección: que el GROUP
# BY salga del MISMO Arel que el ORDER BY, y que una declaración que no puede funcionar falle
# al construir el form y no cuando alguien elige esa agrupación en la pantalla.
class BaliFilterFormGroupByExpressionsTest < ActiveSupport::TestCase
  # Un ransacker (expresión SQL), un camino de asociación y una columna de siempre, en el
  # mismo form: las tres formas conviven.
  class MixedGroupingsFilterForm < Bali::FilterForm
    group_by_attribute :genre
    group_by_attribute :budget_band, label: "Presupuesto"
    group_by_attribute :studio_name, label: "Estudio", value: ->(movie) { movie.studio&.name }

    attribute :genre_eq
  end

  def setup
    @acme = Tenant.create!(name: "Acme")
    @orbit = Tenant.create!(name: "Orbit")

    @big = Movie.create!(name: "Big", genre: "Action", budget: 90_000_000, studio: @acme)
    @mid = Movie.create!(name: "Mid", genre: "Action", budget: 6_000_000, studio: @acme)
    @small = Movie.create!(name: "Small", genre: "Drama", budget: 100_000, studio: @orbit)
    @broke = Movie.create!(name: "Broke", genre: "Drama", budget: nil, studio: @orbit)
  end

  def group_params(group_by, q: {})
    ActionController::Parameters.new(q: ActionController::Parameters.new(q), group_by: group_by)
  end

  def form(group_by, **options)
    MixedGroupingsFilterForm.new(Movie.all, group_params(group_by, **options))
  end

  # --- Ransacker ---

  # La cabeza del issue: `group(:budget_band)` era `PG::UndefinedColumn` porque el símbolo
  # llegaba crudo. Ahora el GROUP BY corre sobre el CASE del ransacker.
  def test_a_ransacker_groups_instead_of_raising
    assert_equal({ "blockbuster" => 1, "mid" => 1, "indie" => 2 },
                 form("budget_band").group_counts)
  end

  def test_a_ransacker_group_by_runs_on_the_ransackers_own_arel
    sql = form("budget_band").group_by_expression.to_sql

    assert_includes sql, "CASE"
    assert_includes sql, "budget"
  end

  # El ORDER BY del ransacker ya funcionaba y se sigue armando por el param `s` de Ransack:
  # las filas se juntan en bandas antes de que la tabla las pinte.
  def test_a_ransacker_still_orders_through_ransack
    assert_equal([ "budget_band asc" ], form("budget_band").ransack_params["s"])
  end

  # La banda de una fila sale del gemelo en Ruby, y tiene que coincidir con la llave que
  # devolvió el GROUP BY o el encabezado pierde el conteo global.
  def test_a_ransacker_row_reads_its_band_through_the_ruby_twin
    grouped = form("budget_band")

    assert_equal("blockbuster", grouped.group_value_for(@big))
    assert_equal("indie", grouped.group_value_for(@broke))
    assert_includes grouped.group_counts.keys, grouped.group_value_for(@big)
  end

  # --- Camino de asociación ---

  def test_an_association_path_groups_over_the_joined_column
    assert_equal({ "Acme" => 2, "Orbit" => 2 }, form("studio_name").group_counts)
  end

  # El join no lo agrega la agrupación: ya está porque la agrupación se prepende como sort y
  # Ransack lo arma al evaluar la relación. Un join de más sería un producto cartesiano.
  def test_an_association_path_reuses_the_join_ransack_already_built
    sql = form("studio_name").result.to_sql

    assert_equal 1, sql.scan(/JOIN "tenants"/).size
  end

  # Para un camino de asociación no hay `movie.studio_name`: de ahí `value:`.
  def test_an_association_path_reads_its_band_through_the_declared_value
    assert_equal("Acme", form("studio_name").group_value_for(@big))
  end

  # --- Columna real (lo que ya funcionaba) ---

  def test_a_plain_column_keeps_grouping_as_before
    grouped = form("genre")

    assert_equal({ "Action" => 2, "Drama" => 2 }, grouped.group_counts)
    assert_equal("Action", grouped.group_value_for(@big))
  end

  # Las llaves de un enum siguen siendo las etiquetas y no los enteros: el Arel que ahora
  # alimenta al GROUP BY conserva el casteo del tipo de la columna.
  def test_an_enum_column_still_returns_label_keys
    enum_form = Class.new(Bali::FilterForm) { group_by_attribute :status }
    @big.update!(status: :done)

    assert_equal({ "draft" => 3, "done" => 1 },
                 enum_form.new(Movie.all, group_params("status")).group_counts)
  end

  # --- Filtros y suspensión siguen mandando ---

  def test_group_counts_of_an_expression_respect_active_filters
    filtered = form("budget_band", q: { genre_eq: "Action" })

    assert_equal({ "blockbuster" => 1, "mid" => 1 }, filtered.group_counts)
  end

  def test_group_value_is_nil_when_no_grouping_is_applied
    assert_nil form(nil).group_value_for(@big)
  end

  # --- `sql:` explícito ---

  # La escapatoria: una expresión que ni una columna ni un ransacker dicen. Manda sobre las
  # DOS mitades, porque agrupar por una expresión y ordenar por otra no junta nada.
  BUDGETED_SQL = "CASE WHEN movies.budget IS NULL THEN 'sin presupuesto' " \
                 "ELSE 'con presupuesto' END"

  class ExplicitSqlFilterForm < Bali::FilterForm
    group_by_attribute :budgeted,
                       label: "Presupuesto",
                       sql: -> { BUDGETED_SQL },
                       value: ->(movie) { movie.budget.present? ? "con presupuesto" : "sin presupuesto" }
  end

  def explicit_form
    ExplicitSqlFilterForm.new(Movie.all, group_params("budgeted"))
  end

  # Las llaves siguen siendo las que devolvió el GROUP BY —crudas—, así que la expresión y
  # el `value:` tienen que hablar el mismo idioma o el encabezado pierde el conteo global.
  def test_an_explicit_sql_expression_drives_the_group_by
    grouped = explicit_form

    assert_equal({ "con presupuesto" => 3, "sin presupuesto" => 1 }, grouped.group_counts)
    assert_equal("sin presupuesto", grouped.group_value_for(@broke))
    assert_includes grouped.group_counts.keys, grouped.group_value_for(@broke)
  end

  # No pasa por el param `s` de Ransack —que solo habla de nombres— sino por un reorder
  # sobre la relación ya evaluada.
  def test_an_explicit_sql_expression_orders_the_relation_itself
    assert_nil explicit_form.ransack_params["s"]
    assert_includes explicit_form.result.to_sql, "ORDER BY #{BUDGETED_SQL} ASC"
  end

  # El orden del usuario sobrevive detrás de la agrupación (sort-within-groups), igual que
  # en la mitad que sí pasa por Ransack.
  def test_an_explicit_sql_expression_keeps_the_user_sort_behind_it
    sorted = ExplicitSqlFilterForm.new(
      Movie.all,
      ActionController::Parameters.new(q: { s: "name desc" }, group_by: "budgeted")
    )

    assert_includes sorted.result.to_sql, %(ORDER BY #{BUDGETED_SQL} ASC, "movies"."name" DESC)
  end

  # --- Fallar al declarar, no en la consulta ---

  def test_an_attribute_that_is_neither_column_ransacker_nor_path_raises_on_build
    bogus = Class.new(Bali::FilterForm) { group_by_attribute :lo_que_sea }

    error = assert_raises(ArgumentError) { bogus.new(Movie.all, group_params(nil)) }
    assert_match(/group_by_attribute :lo_que_sea/, error.message)
    assert_match(/no column, ransacker or reachable association path/, error.message)
  end

  # Revienta VENGA O NO el param: si esperara a que alguien elija esa agrupación, seguiría
  # siendo un error de producción sobre una pantalla que cargó bien mil veces.
  def test_the_declaration_raises_even_when_no_group_by_param_arrives
    bogus = Class.new(Bali::FilterForm) { group_by_attribute :lo_que_sea }

    assert_raises(ArgumentError) { bogus.new(Movie.all, ActionController::Parameters.new) }
  end

  # El GROUP BY resuelve pero la fila no se puede leer: `movie.studio_name` es NoMethodError.
  def test_an_association_path_without_a_value_reader_raises_on_build
    reader_less = Class.new(Bali::FilterForm) { group_by_attribute :studio_name }

    error = assert_raises(ArgumentError) { reader_less.new(Movie.all, group_params(nil)) }
    assert_match(/Pass `value:`/, error.message)
  end

  # Un `sql:` explícito exime de la primera mitad: es la escapatoria para lo que Ransack no
  # sabe nombrar.
  def test_an_explicit_sql_declaration_needs_no_ransack_name
    assert_nothing_raised { explicit_form }
  end

  # Sin modelo no hay nada que verificar, y una validación que revienta sobre un scope que
  # no es una relación sería peor que la que no existía.
  def test_a_scope_without_a_model_skips_validation
    assert_nothing_raised do
      Class.new(Bali::FilterForm) { group_by_attribute :lo_que_sea }.new([], group_params(nil))
    end
  end
end

# #1156, half 2. Grouping ORDERS BY the group expression, and over a scope with `.distinct`
# Postgres requires every ORDER BY expression to appear in the select list. Three of the four
# grouping shapes are absent from `SELECT DISTINCT movies.*` — an association path, a ransacker
# and an explicit `sql:`.
#
# sqlite accepts all four, so the Postgres failure does NOT reproduce in this repo: these tests
# raise the adapter exception from the scope itself.
class BaliFilterFormGroupByDistinctTest < ActiveSupport::TestCase
  PG_DISTINCT_MESSAGE = "PG::InvalidColumnReference: ERROR:  for SELECT DISTINCT, " \
                        "ORDER BY expressions must appear in select list\n" \
                        'LINE 1: SELECT DISTINCT "movies".* FROM "movies" ...'

  MYSQL_DISTINCT_MESSAGE = "Mysql2::Error: Expression #1 of ORDER BY clause is not in SELECT " \
                           "list, references column 'db.tenants.name' which is not in SELECT " \
                           "list; this is incompatible with DISTINCT"

  class DistinctGroupingsFilterForm < Bali::FilterForm
    group_by_attribute :genre
    group_by_attribute :budget_band, label: "Budget"
    group_by_attribute :studio_name, label: "Studio", value: ->(movie) { movie.studio&.name }
    group_by_attribute :budgeted,
                       label: "Budgeted",
                       sql: -> { "CASE WHEN movies.budget IS NULL THEN 'no' ELSE 'yes' END" },
                       value: ->(movie) { movie.budget.present? ? "yes" : "no" }
  end

  # Goes on the scope so it sits BELOW the diagnostics module Bali adds in `result`.
  def failing_adapter(message)
    Module.new do
      define_method(:exec_queries) { |&_block| raise ActiveRecord::StatementInvalid, message }
    end
  end

  def form(group_by, message: PG_DISTINCT_MESSAGE, scope: Movie.all.distinct)
    DistinctGroupingsFilterForm.new(
      scope.extending(failing_adapter(message)),
      ActionController::Parameters.new(q: ActionController::Parameters.new({}), group_by: group_by)
    )
  end

  # All FOUR shapes go through the same rescue: the association path and the ransacker order
  # through Ransack's `s` param and never enter `apply_group_by_sql_order`, so a guard placed
  # there left the bug alive exactly where it was reported.
  %w[genre budget_band studio_name budgeted].each do |attribute|
    define_method("test_the_distinct_conflict_is_translated_for_#{attribute}") do
      grouped = form(attribute)
      error = assert_raises(Bali::FilterForm::GroupByOrderingError) { grouped.result.to_a }

      assert_match(/#{attribute}/, error.message)
      assert_match(/SELECT DISTINCT/, error.message)
    end

    # Compared against what the relation actually emits rather than a constant, so the test
    # keeps measuring if Arel changes how it writes it. Two of the four shapes resolve to an
    # `Arel::Attributes::Attribute`, which does NOT respond to `to_sql`: falling back to `to_s`
    # put a Struct's inspect of the whole model in the message (1726 characters for `genre`).
    define_method("test_the_message_names_the_offending_order_by_for_#{attribute}") do
      grouped = form(attribute)
      emitted = grouped.result.to_sql[/ORDER BY (.+?)(?: LIMIT|\z)/m, 1]
      error = assert_raises(Bali::FilterForm::GroupByOrderingError) { grouped.result.to_a }

      assert_includes(error.message, "ORDER BY #{emitted}")
      refute_match(/#<struct/, error.message, "a Struct dump names nothing")
      assert_operator(error.message.length, :<, 900, error.message)
    end
  end

  # The association path is the shape that reported the issue.
  def test_the_association_path_message_names_the_joined_column
    error = assert_raises(Bali::FilterForm::GroupByOrderingError) { form("studio_name").result.to_a }

    assert_match(/ORDER BY "tenants"\."name" ASC/, error.message)
  end

  def test_the_message_names_the_listing_and_the_three_ways_out
    error = assert_raises(Bali::FilterForm::GroupByOrderingError) { form("studio_name").result.to_a }

    assert_match(/DistinctGroupingsFilterForm/, error.message)
    assert_match(/\.distinct/, error.message)
    assert_match(/select/i, error.message)
    assert_match(/column/i, error.message)
  end

  def test_the_original_adapter_error_survives_as_the_cause
    error = assert_raises(Bali::FilterForm::GroupByOrderingError) { form("studio_name").result.to_a }

    assert_kind_of(ActiveRecord::StatementInvalid, error.cause)
    assert_match(/InvalidColumnReference/, error.cause.message)
  end

  def test_the_mysql_wording_is_translated_too
    error = assert_raises(Bali::FilterForm::GroupByOrderingError) do
      form("studio_name", message: MYSQL_DISTINCT_MESSAGE).result.to_a
    end

    assert_match(/studio_name/, error.message)
  end

  def test_any_other_adapter_failure_passes_through_untouched
    error = assert_raises(ActiveRecord::StatementInvalid) do
      form("studio_name", message: "SQLite3::SQLException: no such table: movies").result.to_a
    end

    assert_match(/no such table/, error.message)
  end

  # With no grouping applied there is nobody to blame: the ORDER BY is the host's.
  def test_without_an_applied_grouping_the_adapter_error_is_left_alone
    assert_raises(ActiveRecord::StatementInvalid) { form(nil).result.to_a }
  end

  def test_a_suspended_grouping_leaves_the_adapter_error_alone
    suspended = DistinctGroupingsFilterForm.new(
      Movie.all.distinct.extending(failing_adapter(PG_DISTINCT_MESSAGE)),
      ActionController::Parameters.new(group_by: "studio_name", view: "grid")
    )

    assert_raises(ActiveRecord::StatementInvalid) { suspended.result.to_a }
  end

  # `to_a` and not `pluck`: the module wraps `exec_queries`, which `pluck` never reaches.
  def test_the_diagnostics_do_not_change_the_result
    plain = DistinctGroupingsFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: "genre")
    )

    assert_equal(Movie.order(:genre).map(&:id), plain.result.to_a.map(&:id))
  end

  # Bali does not materialize the relation — the host writes `pagy(form.result)` and walks it
  # in the view — so the rescue has to survive the spawns pagy chains. Move it from
  # `relation.extending(module)` to wrapping a call and everything above stays green while the
  # bug returns in production.
  def test_the_rescue_survives_the_spawns_pagy_chains
    grouped = form("studio_name")

    [
      -> { grouped.result.limit(8).offset(0).to_a },
      -> { grouped.result.includes(:studio).limit(8).offset(0).to_a },
      -> { grouped.result.first },
      -> { grouped.result.find_each { |_movie| nil } }
    ].each_with_index do |materialize, index|
      error = assert_raises(Bali::FilterForm::GroupByOrderingError, "spawn ##{index}", &materialize)
      assert_kind_of(ActiveRecord::StatementInvalid, error.cause)
    end
  end

  # The global counts are the live case that carries no ORDER BY (`group_counts` unscopes it).
  def test_a_query_without_an_order_by_is_left_alone
    plain = DistinctGroupingsFilterForm.new(
      Movie.all.distinct, ActionController::Parameters.new(group_by: "studio_name")
    )

    assert_nothing_raised { plain.result.count(:all) }
    assert_nothing_raised { plain.group_counts }
  end
end
