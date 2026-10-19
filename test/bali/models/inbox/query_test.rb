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
