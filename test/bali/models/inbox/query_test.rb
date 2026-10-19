# frozen_string_literal: true

require "test_helper"

# #1512 — what is waiting on one person, gathered from the host's providers.
class BaliInboxQueryTest < ActiveSupport::TestCase
  class TasksProvider
    include Bali::Inbox::Provider

    def kind = :task

    def pending_for(_user) = Task.where.not(status: :done).order(:id)

    def build_item(task, user:) = item(task, title: task.title, due_at: task.due_date, href: "/tasks/#{task.id}")
  end

  # An Array, not a relation: `pending_for` may filter in Ruby.
  class DocumentsProvider
    include Bali::Inbox::Provider

    def kind = :acknowledgment

    def pending_for(user) = Document.published.reject { |document| document.acknowledged_by?(user) }

    def build_item(document, user:) = item(document, title: document.title)
  end

  # What must be seen first whatever its date — an emergency before an alert.
  class UrgentProvider
    include Bali::Inbox::Provider

    def kind = :urgent

    def priority = 1

    def pending_for(_user) = Task.done.order(:id)

    def build_item(task, user:) = item(task, title: task.title, due_at: task.due_date)
  end

  # One kind across modules: the module comes from each record.
  class SpreadProvider
    include Bali::Inbox::Provider

    def kind = :spread

    def pending_for(_user) = Task.in_progress.order(:id)

    def build_item(task, user:) = item(task, title: task.title, module_key: :docs)
  end

  # Built by hand, with the module read off a record column: both arrive as Strings.
  class ColumnProvider
    include Bali::Inbox::Provider

    def kind = :column

    def pending_for(_user) = Task.in_progress.order(:id)

    def build_item(task, user:) = Bali::Inbox::Item.new(kind: "column", record: task, title: task.title, module_key: "docs")
  end

  def setup
    @providers = Bali.inbox_providers
    @kinds = Bali.notice_kinds
    Bali.inbox_providers = { demo: [ TasksProvider.name ], docs: [ DocumentsProvider.name ] }
    @ana = User.create!(name: "Ana")
    @project = Project.create!(name: "Launch")
  end

  def teardown
    Bali.inbox_providers = @providers
    Bali.notice_kinds = @kinds
  end

  def task(title, due: nil, status: :todo)
    @project.tasks.create!(title: title, due_date: due, status: status)
  end

  def document(title, status: :published)
    Document.create!(title: title, author_name: "Ana", status: status)
  end

  def query = Bali::Inbox::Query.new(@ana)

  def test_count_sums_every_provider
    task("Write")
    task("Ship", status: :done)
    document("Policy")

    assert_equal 2, query.count
    assert_equal({ task: 1, acknowledgment: 1 }, query.counts_by_kind)
  end

  def test_items_sort_overdue_this_week_later_undated_last_then_title
    travel_to Time.zone.local(2026, 10, 18, 12) do
      task("Later", due: Date.new(2026, 11, 30))
      task("Undated b")
      task("Undated a")
      task("Overdue", due: Date.new(2026, 10, 10))
      task("Friday", due: Date.new(2026, 10, 23))
      task("Today", due: Date.new(2026, 10, 18))

      items = query.items

      assert_equal [ "Overdue", "Today", "Friday", "Later", "Undated a", "Undated b" ], items.map(&:title)
      assert_equal %i[overdue this_week this_week later later later], items.map(&:band)
    end
  end

  # The bands still lead — the page and the popover group by them —; within a band, a provider with
  # a higher priority comes first: Centinela's fresh emergency before its older alerts.
  def test_within_a_band_a_provider_with_a_higher_priority_comes_first
    Bali.inbox_providers = { demo: [ TasksProvider.name, UrgentProvider.name ] }
    travel_to Time.zone.local(2026, 10, 18, 12) do
      task("Old overdue", due: Date.new(2026, 10, 1))
      task("Fresh urgent", due: Date.new(2026, 10, 17), status: :done)
      task("Urgent, undated", status: :done)

      items = query.items

      assert_equal [ "Fresh urgent", "Old overdue", "Urgent, undated" ], items.map(&:title)
      assert_equal %i[overdue overdue later], items.map(&:band)
    end
  end

  def test_an_item_naming_its_own_module_keeps_it
    Bali.inbox_providers = { demo: [ TasksProvider.name, SpreadProvider.name ], docs: [] }
    spread = task("Spread", status: :in_progress)
    task("Write")

    assert_equal :docs, query.items(kind: :spread).sole.module_key
    assert_equal :docs, query.find(:spread, spread.to_gid_param).module_key
    assert_equal [ [ :spread, "Spread" ] ], query.items(module_key: :docs).map { [ it.kind, it.title ] }
    assert_equal [ [ :task, "Spread" ], [ :task, "Write" ] ], query.items(module_key: :demo).map { [ it.kind, it.title ] }
    assert_equal %i[demo docs], query.modules
  end

  def test_an_item_built_with_strings_is_filtered_and_sorted_like_any_other
    Bali.inbox_providers = { demo: [ TasksProvider.name, ColumnProvider.name ], docs: [] }
    task("Spread", status: :in_progress)

    assert_equal [ [ :column, "Spread" ] ], query.items(module_key: :docs).map { [ it.kind, it.title ] }
    assert_equal [ :column ], query.items(kind: :column).map(&:kind)
  end

  def test_items_filter_by_kind_and_by_module
    task("Write")
    document("Policy")

    assert_equal [ "Write" ], query.items(kind: :task).map(&:title)
    assert_equal [ "Policy" ], query.items(module_key: :docs).map(&:title)
    assert_equal %i[demo docs], query.modules
  end

  def test_an_item_carries_its_module_and_kind
    task("Write")

    assert_equal [ :task, :demo ], [ query.items.first.kind, query.items.first.module_key ]
  end

  def test_a_provider_over_the_fetch_cap_is_capped_and_says_so
    now = Time.current
    Task.insert_all(Array.new(Bali::Inbox::Query::FETCH_CAP + 1) do |n|
      { project_id: @project.id, title: "T#{n}", status: 1, created_at: now, updated_at: now }
    end)

    inbox = query

    assert_equal Bali::Inbox::Query::FETCH_CAP, inbox.items.size
    assert inbox.capped?
    assert_equal Bali::Inbox::Query::FETCH_CAP + 1, inbox.count
  end

  def test_a_module_filter_is_not_capped_by_another_modules_provider
    now = Time.current
    Task.insert_all(Array.new(Bali::Inbox::Query::FETCH_CAP + 1) do |n|
      { project_id: @project.id, title: "T#{n}", status: 1, created_at: now, updated_at: now }
    end)
    document("Policy")

    inbox = query

    assert_equal [ "Policy" ], inbox.items(module_key: :docs).map(&:title)
    assert_not inbox.capped?
  end

  def test_find_returns_the_item_for_a_pending_record
    write = task("Write")

    assert_equal write, query.find(:task, write.to_gid_param)&.record
  end

  def test_find_works_over_an_array_provider
    policy = document("Policy")

    assert_equal policy, query.find(:acknowledgment, policy.to_gid_param)&.record
  end

  def test_find_returns_nil_for_whatever_is_not_pending_for_this_user
    done = task("Ship", status: :done)
    deleted = task("Gone").tap(&:destroy!)
    pending = task("Write")
    same_id_document = Document.create!(id: pending.id, title: "Same id", author_name: "Ana")

    assert_nil query.find(:task, done.to_gid_param), "a resolved record"
    assert_nil query.find(:task, deleted.to_gid_param), "a deleted record"
    assert_nil query.find(:task, same_id_document.to_gid_param), "another model's gid with a pending id"
    assert_nil query.find(:movie, pending.to_gid_param), "an unknown kind"
    assert_nil query.find(:task, "not-a-gid"), "garbage"
  end

  def test_a_kind_registered_twice_raises_naming_both_modules
    Bali.inbox_providers = { demo: [ TasksProvider.name ], docs: [ TasksProvider.name ] }

    error = assert_raises(ArgumentError) { query.count }
    assert_match(/:task.*demo.*docs/, error.message)
  end

  def test_a_notice_kind_announcing_a_kind_no_provider_has_raises
    Bali.notice_kinds = { movie_assigned: { announces: :movie } }

    error = assert_raises(ArgumentError) { query.count }
    assert_match(/movie_assigned.*:movie/, error.message)
  end
end
