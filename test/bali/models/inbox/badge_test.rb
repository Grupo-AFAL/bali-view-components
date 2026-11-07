# frozen_string_literal: true

require "test_helper"

# #1512 — the topbar icon's two numbers, cached per person for a minute.
class BaliInboxBadgeTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  class TasksProvider
    include Bali::Inbox::Provider

    def kind = :task

    def pending_for(_user) = Task.where.not(status: :done)

    def build_item(task, user:) = item(task, title: task.title)
  end

  class DocumentsProvider
    include Bali::Inbox::Provider

    def kind = :acknowledgment

    def pending_for(_user) = Document.published

    def build_item(document, user:) = item(document, title: document.title)
  end

  def setup
    @cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @providers = Bali.inbox_providers
    @kinds = Bali.notice_kinds
    Bali.inbox_providers = { demo: [ TasksProvider.name ] }
    Bali.notice_kinds = { task_assigned: { announces: :task }, movie_released: {} }
    @ana = User.create!(name: "Ana")
    @task = Project.create!(name: "Launch").tasks.create!(title: "Write", status: :todo)
  end

  def teardown
    Rails.cache = @cache
    Bali.inbox_providers = @providers
    Bali.notice_kinds = @kinds
  end

  def release_notice = @task.notify(recipient: @ana, kind: :movie_released, message: "Alien is out")

  def test_counts_what_is_pending_and_the_unread_notices_that_do_not_announce
    release_notice
    @task.notify(recipient: @ana, kind: :task_assigned, message: "You were assigned Write")

    assert_equal [ 1, 1 ], Bali::Inbox::Badge.for(@ana).deconstruct
  end

  # A host page that already counted its own module (afal-apps' Inicio, TDFlow's) hands that over:
  # Bali counts every other module and the unread notices, by the rule `for` uses.
  def test_write_from_takes_the_hosts_count_for_its_module_and_counts_the_rest
    Bali.inbox_providers = { demo: [ TasksProvider.name ], docs: [ DocumentsProvider.name ] }
    Document.create!(title: "Policy", author_name: "Ana", status: :published)
    release_notice

    written = Bali::Inbox::Badge.write_from(@ana, pending_by_module: { demo: 6 })

    assert_equal [ 7, 1 ], written.deconstruct, "6 from the host, 1 document, 1 unread notice"
    assert_equal written, Bali::Inbox::Badge.compute(@ana, pending_by_module: { "demo" => 6 })
    assert_queries_count(0) { assert_equal written, Bali::Inbox::Badge.for(@ana) }
  end

  # A misspelt key would add the host's number to a count that still asks every provider.
  def test_write_from_refuses_a_key_with_no_provider_under_it
    Bali.inbox_providers = { demo: [ TasksProvider.name ], docs: [] }

    [ { tdflow: 6 }, { "docs" => 6 } ].each do |counted|
      error = assert_raises(ArgumentError) { Bali::Inbox::Badge.write_from(@ana, pending_by_module: counted) }
      assert_match(/no provider under :#{counted.keys.sole}/, error.message)
    end
    assert_not Rails.cache.exist?(Bali::Inbox::Badge.key(@ana))
  end

  def test_a_warm_cache_issues_no_query
    Bali::Inbox::Badge.for(@ana)

    assert_queries_count(0) { Bali::Inbox::Badge.for(@ana) }
  end

  def test_it_stays_stale_until_something_expires_it
    Bali::Inbox::Badge.for(@ana)
    @task.update!(status: :done)

    assert_equal 1, Bali::Inbox::Badge.for(@ana).pending
  end

  def test_a_new_notice_expires_the_recipients_badge
    Bali::Inbox::Badge.for(@ana)
    release_notice

    assert_equal 1, Bali::Inbox::Badge.for(@ana).unread
  end

  # After the commit, so a broadcast that fails must not turn the writer's request into a 500 —
  # its step is already saved, and a person resubmitting it writes it twice.
  def test_a_broadcast_that_fails_is_reported_and_the_notice_stands
    # Turbo extends the channel with it, so removing the override brings Turbo's back.
    channel = Turbo::StreamsChannel.singleton_class
    channel.define_method(:broadcast_replace_to) { |*| raise IOError, "solid_cable is down" }

    notice = nil
    assert_error_reported(IOError) { notice = release_notice }

    assert_predicate notice, :persisted?
  ensure
    channel.remove_method :broadcast_replace_to
  end

  def test_a_new_notice_tells_the_recipients_open_pages_to_refetch_carrying_no_count
    # Turbo's own name for `turbo_stream_from ana, :bali_inbox`, which `broadcasting_for` would
    # prefix with the channel's.
    stream = "#{@ana.to_gid_param}:bali_inbox"

    assert_broadcasts(stream, 1) { release_notice }

    message = ActiveSupport::JSON.decode(broadcasts(stream).last)
    assert_match %(target="#{Bali::Topbar::Inbox::Component::SIGNAL_ID}"), message
    refute_match(/\d+ pendientes|>1</, message)
  end

  def test_mark_all_read_expires_it
    release_notice
    Bali::Inbox::Badge.for(@ana)
    Bali::Notice.mark_all_read!(@ana)

    assert_equal 0, Bali::Inbox::Badge.for(@ana).unread
  end

  def test_reading_one_notice_expires_it
    notice = release_notice
    Bali::Inbox::Badge.for(@ana)
    notice.mark_read!

    assert_equal 0, Bali::Inbox::Badge.for(@ana).unread
  end
end
