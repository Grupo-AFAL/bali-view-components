# frozen_string_literal: true

require "test_helper"

# #999: the controller-side seam that closes the persistence circuit. Each test
# pins one of the three internal contracts the concern absorbs — the storage id
# derivation, the `bali_persist_*` cookie format, and `Bali.filter_context`.
class BaliFilterableTest < ActiveSupport::TestCase
  class FakeController
    include Bali::Filterable

    attr_reader :params, :cookies, :request, :redirected_to

    def initialize(params: {}, cookies: {}, path: "admin/accounts", user: nil,
                   request: ActionDispatch::TestRequest.create)
      @params = ActionController::Parameters.new(params)
      @cookies = cookies
      @path = path
      @user = user
      @request = request
    end

    def controller_path = @path
    def current_user = @user
    def redirect_to(url) = @redirected_to = url
  end

  FakeUser = Struct.new(:id)

  # The dummy app's initializer overrides `Bali.filter_context` with its
  # visitor-token lambda (which FakeController cannot answer); these tests pin
  # the ENGINE's contract, so they run against the engine's own default shape.
  def setup
    @previous_filter_context = Bali.filter_context
    Bali.filter_context = ->(controller) { controller.try(:current_user)&.id }
  end

  def teardown
    Bali.filter_context = @previous_filter_context
  end

  def form(controller = FakeController.new, **options)
    controller.filter_form(Bali::FilterForm, Movie.all, **options)
  end

  def test_derives_storage_id_from_controller_path_with_slashes_dashed
    assert_equal "admin-accounts", form.storage_id
  end

  # Derived from the controller and not from the form class: one form class can
  # serve several listings, and the class name would collide their identities.
  def test_explicit_storage_id_wins
    assert_equal "bulk-provision-7", form(storage_id: "bulk-provision-7").storage_id
  end

  def test_reads_the_persistence_cookie_the_toggle_writes
    on = FakeController.new(cookies: { "bali_persist_admin-accounts" => "1" })
    off = FakeController.new(cookies: { "bali_persist_admin-accounts" => "0" })

    assert form(on).persist_enabled?
    refute form(off).persist_enabled?
    refute form.persist_enabled?
  end

  # Reading the cookie IS the opt-in read, whichever way it answers: the form
  # never trips DataTable's unwired-persistence warning through this path.
  def test_the_concern_always_counts_as_a_read_opt_in
    assert_predicate form, :persistence_opt_in_read?
  end

  def test_explicit_persist_enabled_wins_over_the_cookie
    on = FakeController.new(cookies: { "bali_persist_admin-accounts" => "1" })
    refute form(on, persist_enabled: false).persist_enabled?
  end

  def test_context_comes_from_bali_filter_context
    assert_equal 42, form(FakeController.new(user: FakeUser.new(42))).context
    assert_nil form.context
  end

  def test_explicit_context_wins_including_an_explicit_nil
    with_filter_context(->(_controller) { "derived" }) do
      assert_equal "x", form(context: "x").context
      assert_nil form(context: nil).context
    end
  end

  def test_a_nil_filter_context_config_yields_no_context
    with_filter_context(nil) do
      assert_nil form(FakeController.new(user: FakeUser.new(42))).context
    end
  end

  def test_extra_kwargs_pass_through_to_the_form
    assert_equal %i[name], form(search_fields: %i[name]).search_fields
  end

  # #1096. Public because a host that decides ANYTHING from the opt-in — a redirect to a
  # default filter, a banner — would otherwise spell `bali_persist_<id>` itself, which is
  # the convention this concern exists to keep on one side of the wall.
  def test_the_persistence_signal_is_public_api
    on = FakeController.new(cookies: { "bali_persist_admin-accounts" => "1" })

    assert_includes Bali::Filterable.public_instance_methods, :filter_persistence_enabled?
    assert on.filter_persistence_enabled?("admin-accounts")
    refute FakeController.new.filter_persistence_enabled?("admin-accounts")
  end

  # With no argument it answers for THIS listing, the same identity #filter_form derives.
  def test_the_persistence_signal_derives_the_storage_id_like_filter_form_does
    on = FakeController.new(cookies: { "bali_persist_admin-accounts" => "1" })

    assert on.filter_persistence_enabled?
    refute on.filter_persistence_enabled?("some-other-listing")
  end

  # It was private until #1096 and an app was already calling it (gobierno-corporativo#877);
  # renaming it out from under them would fail the exact way that issue is about — silently.
  def test_the_old_private_name_still_answers_and_deprecates
    on = FakeController.new(cookies: { "bali_persist_admin-accounts" => "1" })

    assert_deprecated(/filter_persistence_enabled/, Bali.deprecator) do
      assert on.send(:bali_filter_persistence_cookie?, "admin-accounts")
    end
  end

  private

  def with_filter_context(value)
    previous = Bali.filter_context
    Bali.filter_context = value
    yield
  ensure
    Bali.filter_context = previous
  end
end

class BaliFilterFormPersistenceOptInTest < ActiveSupport::TestCase
  def test_nobody_read_the_opt_in_by_default
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}))

    refute_predicate form, :persist_enabled?
    refute_predicate form, :persistence_opt_in_read?
  end

  # An explicit false is a READ opt-in ("this browser said no"), which is a
  # different thing from nobody having looked — only the latter warns.
  def test_an_explicit_false_counts_as_read
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}), persist_enabled: false)

    refute_predicate form, :persist_enabled?
    assert_predicate form, :persistence_opt_in_read?
  end

  def test_an_explicit_true_counts_as_read
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}), persist_enabled: true)

    assert_predicate form, :persist_enabled?
    assert_predicate form, :persistence_opt_in_read?
  end
end

# The safety net: the toggle is about to render, so a form nobody wired warns
# in development instead of failing silently for the third app in a row. Only
# there — in a host's test suite the warning is noise (#1029) — so every test
# here renders under a stubbed development env, including the silent ones:
# without the stub they would pass because of the env gate, not the wiring.
class BaliDataTablePersistenceWarningTest < ComponentTestCase
  def setup
    Bali::DataTable::Component.persistence_warnings_issued = Set.new
  end

  def test_warns_when_the_toggle_renders_and_nobody_read_the_opt_in
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}), storage_id: "unwired-#{object_id}")

    assert_match(/persistence toggle will render.*persist_enabled/m, capture_bali_log { render_data_table(form) })
  end

  def test_warns_when_the_opt_in_was_read_but_there_is_no_context
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}), storage_id: "no-context-#{object_id}",
                                               persist_enabled: true)

    assert_match(/no.*context/m, capture_bali_log { render_data_table(form) })
  end

  def test_stays_silent_when_the_circuit_is_closed
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}), storage_id: "wired-#{object_id}",
                                               persist_enabled: false, context: "user-1")

    assert_empty capture_bali_log { render_data_table(form) }
  end

  def test_stays_silent_without_a_storage_id
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}))

    assert_empty capture_bali_log { render_data_table(form) }
  end

  # The #1029 fix itself: an unwired form under the REAL (test) env — no stub —
  # stays silent, so a host's suite never logs Bali's development-only advice.
  def test_stays_silent_in_a_test_env_even_when_unwired
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new({}),
                                storage_id: "test-env-#{object_id}")

    assert_empty capture_bali_log { render_data_table(form, stub_env: false) }
  end

  private

  def render_data_table(form, stub_env: true)
    return render_table(form) unless stub_env

    previous = Rails.env
    Rails.env = "development"
    render_table(form)
  ensure
    Rails.env = previous if stub_env
  end

  def render_table(form)
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_simple_filters(filters: [
                              { attribute: :status, collection: [ %w[On on] ], label: "Status" }
                            ])
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
  end

  def capture_bali_log
    io = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    yield
    io.string.scan(/\[Bali\].*/).join("\n")
  ensure
    Rails.logger = previous
  end
end

# #1096. The controller half of `default:`: a listing whose default question lives in the
# URL keeps it through sorting and paging (Ransack's `sort_link` and the pagination compose
# their hrefs out of `params`), shows it as a removable condition, and travels in a link.
class BaliFilterableDefaultFiltersTest < ActiveSupport::TestCase
  FormWithDefault = Class.new(Bali::FilterForm) do
    filter_attribute :status, type: :select, simple: true, default: "active"
  end

  FormWithoutDefaults = Class.new(Bali::FilterForm) do
    filter_attribute :status, type: :select, simple: true
  end

  def test_a_bare_listing_url_is_sent_to_its_defaults
    controller = build

    assert controller.redirect_to_default_filters(FormWithDefault)
    assert_equal "/personas?q%5Bstatus_eq%5D=active", controller.redirected_to
  end

  def test_the_rest_of_the_query_string_survives_the_redirect
    controller = build(query: "view=grid&page=2")

    assert controller.redirect_to_default_filters(FormWithDefault)
    assert_equal "/personas?page=2&q%5Bstatus_eq%5D=active&view=grid", controller.redirected_to
  end

  # No loop: the redirect's own destination carries `q`, which is the first gate.
  def test_the_redirect_destination_does_not_redirect_again
    controller = build
    controller.redirect_to_default_filters(FormWithDefault)
    landed = build(params: { q: { status_eq: "active" } }, query: "q%5Bstatus_eq%5D=active")

    refute landed.redirect_to_default_filters(FormWithDefault)
  end

  def test_a_form_with_no_defaults_never_redirects
    controller = build

    refute controller.redirect_to_default_filters(FormWithoutDefaults)
    assert_nil controller.redirected_to
  end

  # The four gates, each one the user having already answered. `q` covers filtering AND
  # sorting: a sorted URL carries `q[s]`, so the default is not re-imposed on the way back.
  def test_a_url_that_already_talks_about_filters_is_left_alone
    [ { q: { s: "name asc" } }, { q: { status_eq: "" } }, { clear_filters: "true" },
      { saved_view: "7" } ].each do |params|
      controller = build(params: params)

      refute controller.redirect_to_default_filters(FormWithDefault),
             "#{params.keys.first} must turn the redirect off"
    end
  end

  # The toggle promises "remember what I chose". A default written into the URL on every
  # bare entry is filter params as far as the form can tell, so it would be stored as the
  # last state and nothing else would ever be restored — persistence off, silently.
  def test_filter_persistence_turns_the_redirect_off
    controller = build(cookies: { "bali_persist_mdm-personas" => "1" })

    refute controller.redirect_to_default_filters(FormWithDefault)
  end

  def test_an_explicit_storage_id_is_the_one_consulted
    controller = build(cookies: { "bali_persist_mdm_catalogo_7" => "1" })

    refute controller.redirect_to_default_filters(FormWithDefault,
                                                  storage_id: "mdm_catalogo_7")
    assert controller.redirect_to_default_filters(FormWithDefault)
  end

  # A listing built with instance-level `simple_filters:` has no class to ask, and a
  # default can also depend on the request. Both pass the `q` hash straight in.
  def test_a_plain_params_hash_works_where_there_is_no_form_class
    controller = build

    assert controller.redirect_to_default_filters({ "estado_eq" => "activo" })
    assert_equal "/personas?q%5Bestado_eq%5D=activo", controller.redirected_to
  end

  def test_an_empty_params_hash_never_redirects
    refute build.redirect_to_default_filters({})
  end

  def test_a_non_get_request_is_left_alone
    controller = build(request: ActionDispatch::TestRequest.create("PATH_INFO" => "/personas",
                                                                   "REQUEST_METHOD" => "POST"))

    refute controller.redirect_to_default_filters(FormWithDefault)
  end

  # Rails routes HEAD to the GET action but `request.get?` answers false for it, so a probe
  # would see a listing the fetch that follows does not.
  def test_a_head_request_redirects_like_the_get_it_is_routed_as
    controller = build(request: ActionDispatch::TestRequest.create("PATH_INFO" => "/personas",
                                                                   "REQUEST_METHOD" => "HEAD"))

    assert controller.redirect_to_default_filters(FormWithDefault)
    assert_equal "/personas?q%5Bstatus_eq%5D=active", controller.redirected_to
  end

  private

  def build(params: {}, cookies: {}, query: "", request: nil)
    request ||= ActionDispatch::TestRequest.create("PATH_INFO" => "/personas",
                                                   "QUERY_STRING" => query)
    BaliFilterableTest::FakeController.new(params: params, cookies: cookies,
                                           path: "mdm/personas", request: request)
  end
end
