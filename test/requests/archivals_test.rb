# frozen_string_literal: true

require "test_helper"

# #721 — Bali::ArchivalsController, configured the way a host does it (pattern from
# test/requests/content_versions_test.rb).
class BaliArchivalsRequestTest < ActionDispatch::IntegrationTest
  include ArchivableDeclaration

  CONFIG = %i[archivables archivals_authorize archivals_actor archival_successors].freeze

  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
    @ana = User.create!(name: "Ana")

    @saved = CONFIG.to_h { |name| [ name, Bali.public_send(name) ] }
    Bali.archivables = { "Movie" => ->(_controller, id) { Movie.find_by(id: id) } }
    Bali.archivals_authorize = ->(_controller, _record, _action) { true }
    ana = @ana
    Bali.archivals_actor = ->(_controller) { ana }
    Bali.archival_successors = ->(_controller, movie) { Movie.where.not(id: movie.id) }
  end

  def teardown
    @saved.each { |name, value| Bali.public_send(:"#{name}=", value) }
  end

  def record_params = { record_type: "Movie", record_id: @movie.id }

  def movie_path = "/movies/#{@movie.id}"

  def test_new_serves_the_form_as_a_drawer_body
    get bali.new_archival_path(record_params.merge(return_to: "/admin/movies"))

    assert_response :success
    assert_no_match(/<html/i, response.body)
    assert_select "h2", "Archive"
    assert_select "form[action=?]", bali.archivals_path(record_params)
    assert_select "input[name=return_to][value=?]", "/admin/movies"
  end

  def test_new_drops_a_return_to_that_is_not_a_local_path
    get bali.new_archival_path(record_params.merge(return_to: "javascript:alert(1)"))

    assert_response :success
    assert_select "input[name=return_to]", false
    assert_select "a[href=?]", "javascript:alert(1)", false
  end

  def test_create_archives_as_the_actor_and_redirects_to_the_record
    post bali.archivals_path(record_params),
         params: { archival: { reason: "replaced", successor_id: @remake.id, note: "Remastered" } }

    assert_response :see_other
    assert_redirected_to movie_path
    archival = @movie.reload.archival
    assert_equal [ @ana, "replaced", @remake, "Remastered" ],
                 [ archival.archived_by, archival.reason, archival.successor, archival.note ]
  end

  def test_an_invalid_archival_re_renders_the_form_with_422_and_keeps_the_choice
    post bali.archivals_path(record_params), params: { archival: { reason: "replaced", note: "Soon" } }

    assert_response :unprocessable_entity
    assert_select "input[name='archival[reason]'][value=replaced][checked]"
    assert_select "#archival_successor_id_error", "Successor can't be blank"
    refute @movie.reload.archived?
  end

  def test_a_successor_outside_the_candidates_is_never_stored
    remake = @remake
    Bali.archival_successors = ->(_controller, movie) { Movie.where.not(id: [ movie.id, remake.id ]) }

    post bali.archivals_path(record_params), params: { archival: { reason: "replaced", successor_id: @remake.id } }

    assert_response :unprocessable_entity
    refute @movie.reload.archived?
  end

  def test_a_successor_id_is_never_stored_when_there_are_no_candidates
    Bali.archival_successors = ->(*) { nil }

    post bali.archivals_path(record_params), params: { archival: { reason: "replaced", successor_id: @remake.id } }

    assert_response :unprocessable_entity
    refute @movie.reload.archived?
  end

  def test_return_to_is_followed_only_when_it_is_a_path_of_this_app
    {
      "/admin/movies?page=2" => "/admin/movies?page=2",
      "//evil.example/movies" => movie_path,
      "https://evil.example/movies" => movie_path,
      "javascript:alert(1)" => movie_path,
      "/\\evil.example/movies" => movie_path,
      "/\t/evil.example" => movie_path
    }.each do |given, expected|
      post bali.unarchive_archivals_path(record_params), params: { return_to: given }
      assert_redirected_to expected, "return_to=#{given}"
    end
  end

  def test_archiving_an_archived_record_redirects_and_keeps_the_first_archival
    first = @movie.archive!(by: @ana, reason: :expired)

    post bali.archivals_path(record_params), params: { archival: { reason: "other" } }

    assert_redirected_to movie_path
    assert_equal [ first ], @movie.archivals.to_a
  end

  def test_unarchive_reopens_as_the_actor
    @movie.archive!(by: @ana)

    post bali.unarchive_archivals_path(record_params)

    assert_redirected_to movie_path
    refute @movie.reload.archived?
    assert_equal @ana, @movie.archivals.first.unarchived_by
  end

  def test_unarchive_on_an_irreversible_model_is_not_found
    @movie.archive!(by: @ana)

    with_archivable(successor_required_for: %i[replaced]) do
      post bali.unarchive_archivals_path(record_params)
    end

    assert_response :not_found
    assert @movie.reload.archived?
  end

  # Default-deny, layer 1: an empty whitelist is the factory setting.
  def test_a_record_type_outside_the_whitelist_is_not_found
    Bali.archivables = {}

    get bali.new_archival_path(record_params)
    assert_response :not_found
    post bali.archivals_path(record_params)
    assert_response :not_found
    post bali.unarchive_archivals_path(record_params)
    assert_response :not_found
  end

  def test_a_resolver_that_finds_nothing_is_not_found
    get bali.new_archival_path(record_type: "Movie", record_id: 0)

    assert_response :not_found
  end

  def test_a_whitelisted_model_without_the_concern_is_not_found
    studio = Studio.create!(name: "Never archived", country: "USA", status: :active)
    refute_kind_of Bali::Archivable, studio
    Bali.archivables = { "Studio" => ->(_controller, id) { Studio.find_by(id: id) } }

    get bali.new_archival_path(record_type: "Studio", record_id: studio.id)

    assert_response :not_found
  end

  # Default-deny, layer 2: the lambda lib/bali.rb ships, written out because the dummy opens it.
  def test_a_falsy_authorize_forbids_every_action
    Bali.archivals_authorize = ->(_controller, _record, _action) { false }

    get bali.new_archival_path(record_params)
    assert_response :forbidden
    assert_no_difference "Bali::Archival.count" do
      post bali.archivals_path(record_params), params: { archival: { reason: "expired" } }
    end
    assert_response :forbidden
    post bali.unarchive_archivals_path(record_params)
    assert_response :forbidden
  end

  def test_authorize_receives_the_action
    asked = []
    Bali.archivals_authorize = lambda do |_controller, _record, action|
      asked << action
      action == "new"
    end

    get bali.new_archival_path(record_params)
    post bali.archivals_path(record_params)
    post bali.unarchive_archivals_path(record_params)

    assert_equal %w[new create unarchive], asked
    assert_response :forbidden
  end

  # bali-analytics track rules read these two ivars: gobierno-corporativo's
  # `documentos.documento_archivado`. Renaming one switches that event off with no error.
  def test_create_leaves_the_record_and_the_new_archival_where_track_rules_read_them
    post bali.archivals_path(record_params), params: { archival: { reason: "expired" } }

    assert_equal @movie, controller.instance_variable_get(:@record)
    assert_predicate controller.instance_variable_get(:@archival), :previously_new_record?
  end
end
