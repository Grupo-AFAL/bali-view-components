# frozen_string_literal: true

require "test_helper"

# #709 — el PORO que responde "¿cuánta de la audiencia ya firmó?". La audiencia se inyecta,
# así que estas pruebas la arman a mano igual que lo haría un host.
class BaliReadCoverageTest < ActiveSupport::TestCase
  def setup
    @document = Document.create!(title: "Política de viáticos", author_name: "Ana")
    @ana = User.create!(name: "Ana")
    @beto = User.create!(name: "Beto")
    @caro = User.create!(name: "Caro")
    @dani = User.create!(name: "Dani")
  end

  def coverage(audience:, **options)
    Bali::ReadCoverage.new(@document, audience: audience, **options)
  end

  def test_it_splits_the_audience_into_who_signed_and_who_has_not
    @document.acknowledge(user: @ana)
    @document.acknowledge(user: @beto)

    result = coverage(audience: [ @ana, @beto, @caro, @dani ])

    assert_equal 4, result.total_count
    assert_equal 2, result.confirmed_count
    assert_equal 2, result.pending_count
    assert_equal [ @ana, @beto ], result.confirmed_users
    assert_equal [ @caro, @dani ], result.pending_users
    assert_in_delta 50.0, result.coverage_percentage
  end

  def test_it_ignores_signatures_from_outside_the_injected_audience
    @document.acknowledge(user: @ana)
    @document.acknowledge(user: @dani)

    result = coverage(audience: [ @ana, @beto ])

    assert_equal 2, result.total_count
    assert_equal [ @ana ], result.confirmed_users
    assert_in_delta 50.0, result.coverage_percentage
  end

  def test_nobody_signed_yet
    result = coverage(audience: [ @ana, @beto ])

    assert_equal 0, result.confirmed_count
    assert_in_delta 0.0, result.coverage_percentage
    assert_predicate result, :below_threshold?
  end

  def test_everybody_signed
    [ @ana, @beto ].each { |user| @document.acknowledge(user: user) }

    result = coverage(audience: [ @ana, @beto ])

    assert_in_delta 100.0, result.coverage_percentage
    refute_predicate result, :below_threshold?
  end

  def test_the_percentage_keeps_one_decimal
    @document.acknowledge(user: @ana)

    assert_in_delta 33.3, coverage(audience: [ @ana, @beto, @caro ]).coverage_percentage
  end

  def test_the_threshold_defaults_to_eighty_and_can_be_injected
    assert_equal 80, Bali::ReadCoverage::DEFAULT_THRESHOLD

    @document.acknowledge(user: @ana)
    @document.acknowledge(user: @beto)
    @document.acknowledge(user: @caro)
    audience = [ @ana, @beto, @caro, @dani ]

    assert_in_delta 75.0, coverage(audience: audience).coverage_percentage
    assert_predicate coverage(audience: audience), :below_threshold?
    refute_predicate coverage(audience: audience, threshold: 70), :below_threshold?
  end

  def test_exactly_at_the_threshold_is_not_below_it
    [ @ana, @beto, @caro, @dani ].take(4).each { |user| @document.acknowledge(user: user) }
    audience = [ @ana, @beto, @caro, @dani, User.create!(name: "Eva") ]

    assert_in_delta 80.0, coverage(audience: audience).coverage_percentage
    refute_predicate coverage(audience: audience), :below_threshold?
  end

  # Decisión 709-4. 0/0 no es cero: un registro que nadie tiene que leer no tiene una
  # cobertura del 0%, tiene una cobertura indefinida. Devolver 0.0 pintaría de rojo un
  # tablero por documentos que no le tocan a nadie.
  def test_an_empty_audience_has_no_coverage_rather_than_zero_coverage
    result = coverage(audience: [])

    assert_equal 0, result.total_count
    assert_equal 0, result.confirmed_count
    assert_equal 0, result.pending_count
    assert_empty result.confirmed_users
    assert_empty result.pending_users
    assert_nil result.coverage_percentage
  end

  # Sin nadie a quien exigirle la lectura no hay incumplimiento. Es la separación
  # deliberada de gobierno-corporativo, que responde `true` aquí.
  def test_an_empty_audience_is_not_below_the_threshold
    refute_predicate coverage(audience: []), :below_threshold?
    refute_predicate coverage(audience: [], threshold: 100), :below_threshold?
  end

  def test_it_accepts_a_relation_as_the_audience
    @document.acknowledge(user: @ana)

    result = coverage(audience: User.where(id: [ @ana.id, @beto.id ]).order(:id))

    assert_equal 2, result.total_count
    assert_equal [ @ana ], result.confirmed_users
  end

  # Una sola consulta para el padrón de firmas, sin importar el tamaño de la audiencia.
  def test_it_reads_the_signatures_once
    [ @ana, @beto ].each { |user| @document.acknowledge(user: user) }
    result = coverage(audience: [ @ana, @beto, @caro, @dani ])

    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      result.confirmed_users
      result.pending_users
      result.coverage_percentage
      result.below_threshold?
    end

    assert_equal 1, queries
  end
end
