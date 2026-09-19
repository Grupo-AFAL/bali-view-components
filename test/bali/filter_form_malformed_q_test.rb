# frozen_string_literal: true

require "test_helper"

class MalformedQFilterForm < Bali::FilterForm
  attribute :name_i_cont, :string
end

class MalformedQSimpleFilterForm < Bali::FilterForm
  filter_attribute :genre, type: :select, simple: true, advanced: false,
                   options: [ %w[Action Action], %w[Comedy Comedy] ]
  attribute :genre_eq
end

# `?q=loquesea` — un escalar donde el listado espera un hash. No hace falta sesión ni saber
# nada de la app para escribirlo en la barra de direcciones, así que un listado que se cae
# con eso es un 500 que cualquier visitante dispara.
class FilterFormMalformedQTest < ActiveSupport::TestCase
  test "un q escalar no tumba el form" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_nil form.name_i_cont
  end

  test "un q en array no tumba el form" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: [ "loquesea" ]))

    assert_nil form.name_i_cont
  end

  test "un q basura sale sin filtrar, no vacio" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_equal Movie.count, form.result.count
  end

  # Con filtros simplificados encendidos hay un SEGUNDO `permit` sobre el mismo valor, que
  # corre al construir: si este form se arma y no filtra, los dos pasaron.
  test "un q escalar tampoco tumba el segundo permit de los filtros simplificados" do
    form = MalformedQSimpleFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_equal Movie.count, form.result.count
  end

  # `q[g]` y `q[m]` los lee el panel avanzado, y `q[s]` el orden: los tres salen del mismo
  # valor, así que un escalar los alcanza a todos.
  test "un q escalar no tumba agrupaciones, combinador ni orden" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_nothing_raised { form.result.to_sql }
  end

  # El caso sano, para que el arreglo no se coma el camino normal.
  test "un q hash sigue filtrando" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: { name_i_cont: "Iron" }))

    assert_equal "Iron", form.name_i_cont
  end

  # Un host puede construir el form fuera de una petición —un job, un export— y ahí `params`
  # es un Hash pelado, no ActionController::Parameters.
  test "un hash pelado sigue filtrando" do
    form = MalformedQFilterForm.new(Movie.all, { q: { name_i_cont: "Iron" } })

    assert_equal "Iron", form.name_i_cont
  end

  test "sin params no truena" do
    form = MalformedQFilterForm.new(Movie.all)

    assert_nil form.name_i_cont
  end
end
