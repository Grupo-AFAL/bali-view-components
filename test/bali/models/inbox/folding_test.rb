# frozen_string_literal: true

require "test_helper"

# #1512 — a notice that announces an item is not shown twice: it marks that item «Nuevo» while
# unread, and viewing the item reads it.
class BaliInboxFoldingTest < ActiveSupport::TestCase
  class TasksProvider
    include Bali::Inbox::Provider

    def kind = :task

    def pending_for(_user) = Task.where.not(status: :done)

    def build_item(task, user:) = item(task, title: task.title)
  end

  def setup
    @providers = Bali.inbox_providers
    @kinds = Bali.notice_kinds
    Bali.inbox_providers = { demo: [ TasksProvider.name ] }
    Bali.notice_kinds = { task_assigned: { announces: :task }, task_commented: {} }
    @ana = User.create!(name: "Ana")
    @luis = User.create!(name: "Luis")
    project = Project.create!(name: "Launch")
    @write = project.tasks.create!(title: "Write", status: :todo)
    @ship = project.tasks.create!(title: "Ship", status: :todo)
  end

  def teardown
    Bali.inbox_providers = @providers
    Bali.notice_kinds = @kinds
  end

  def query = Bali::Inbox::Query.new(@ana)

  def fresh_titles(inbox = query)
    items = inbox.items
    fresh = inbox.fresh_keys(items)
    items.select { |item| fresh.include?([ item.record.class.polymorphic_name, item.record.id ]) }.map(&:title)
  end

  def test_an_unread_announcing_notice_marks_its_item
    @write.notify(recipient: @ana, kind: :task_assigned, message: "You were assigned Write")

    assert_equal [ "Write" ], fresh_titles
  end

  def test_another_recipients_a_read_one_or_a_kind_that_does_not_announce_marks_nothing
    @write.notify(recipient: @luis, kind: :task_assigned, message: "Luis was assigned Write")
    @ship.notify(recipient: @ana, kind: :task_assigned, message: "You were assigned Ship").mark_read!
    @ship.notify(recipient: @ana, kind: :task_commented, message: "Luis commented on Ship")

    assert_equal [], fresh_titles
  end

  def test_fresh_keys_is_one_query
    @write.notify(recipient: @ana, kind: :task_assigned, message: "You were assigned Write")
    inbox = query
    items = inbox.items

    assert_queries_count(1) { inbox.fresh_keys(items) }
  end

  def test_mark_seen_reads_the_announcing_notices_of_that_item_only
    write_notice = @write.notify(recipient: @ana, kind: :task_assigned, message: "You were assigned Write")
    ship_notice = @ship.notify(recipient: @ana, kind: :task_assigned, message: "You were assigned Ship")
    comment = @write.notify(recipient: @ana, kind: :task_commented, message: "Luis commented on Write")

    inbox = query
    inbox.mark_seen!(inbox.items.find { |item| item.title == "Write" })

    assert_equal [ false, true, true ], [ write_notice, ship_notice, comment ].map { |notice| notice.reload.unread? }
  end
end
