# frozen_string_literal: true

require "test_helper"

# #999: the controller-side seam that closes the persistence circuit. Each test
# pins one of the three internal contracts the concern absorbs — the storage id
# derivation, the `bali_persist_*` cookie format, and `Bali.filter_context`.
class BaliFilterableTest < ActiveSupport::TestCase
  class FakeController
    include Bali::Filterable

    attr_reader :params, :cookies

    def initialize(params: {}, cookies: {}, path: "admin/accounts", user: nil)
      @params = ActionController::Parameters.new(params)
      @cookies = cookies
      @path = path
      @user = user
    end

    def controller_path = @path
    def current_user = @user
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
# in dev/test instead of failing silently for the third app in a row.
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

  private

  def render_data_table(form)
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
