# frozen_string_literal: true

require "test_helper"

# #1512 — the dummy's InboxesController is the reference host controller: the whole integration
# is `include Bali::Concerns::Controllers::Inbox` and the routes. These walk every action.
class InboxRequestTest < ActionDispatch::IntegrationTest
  class OwnerlessInboxesController < ::InboxesController
    private

    def inbox_owner = nil
  end
  def setup
    @cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @ana = User.demo
    @luis = User.create!(name: "Luis")
    @project = Project.create!(name: "Launch")
    @movie = Tenant.create!(name: "Studio").movies.create!(name: "Alien", status: 0)
  end

  def teardown
    Rails.cache = @cache
  end

  def task(title, due: nil, status: :todo) = @project.tasks.create!(title: title, due_date: due, status: status)

  def released(recipient: @ana, message: "Alien is out", action_url: "/admin/movies")
    @movie.notify(recipient: recipient, kind: :movie_released, message: message, action_url: action_url)
  end

  def assigned(task, recipient: @ana) = task.notify(recipient: recipient, kind: :task_assigned, message: "You got #{task.title}")

  def item_path_for(record, kind: :task) = "/inbox/items/#{kind}/#{record.to_gid_param}"

  # The detail pane: the layout around it echoes the path that was asked for, which is the
  # person's own input and tells them nothing.
  def gone_pane = css_select(".bali-inbox-gone").to_s

  def test_show_renders_te_toca_with_its_bands_pills_and_counts
    travel_to Time.zone.local(2026, 10, 18, 12) do
      task("Overdue", due: Date.new(2026, 10, 10))
      task("Friday", due: Date.new(2026, 10, 23))
      task("Someday")

      get "/inbox"
    end

    assert_response :success
    assert_select "[data-split-view-group-key=overdue]", 1
    assert_select "[data-split-view-group-key=this_week]", 1
    assert_select "[data-split-view-group-key=later]", 1
    assert_select ".split-view-row", 3
    assert_select "a[href*='kind=task']", /3/
  end

  def test_show_tab_notices_lists_listed_notices_newest_first
    released(message: "Older").update_columns(created_at: 2.days.ago)
    released(message: "Newer")
    assigned(task("Write"))

    get "/inbox", params: { tab: "notices" }

    assert_response :success
    assert_equal [ "Newer", "Older" ], css_select(".bali-inbox-notice-message").map { |node| node.text.strip }
  end

  def test_notices_page_20_at_a_time
    21.times { |n| released(message: "Notice #{n}") }

    get "/inbox", params: { tab: "notices" }
    assert_select ".bali-inbox-notice-message", 20

    get "/inbox", params: { tab: "notices", page: 2 }
    assert_select ".bali-inbox-notice-message", 1
  end

  def test_item_renders_the_detail_and_marks_its_folded_notice_read
    write = task("Write")
    notice = assigned(write)

    get item_path_for(write)

    assert_response :success
    assert_select ".bali-inbox-detail", /Write/
    refute notice.reload.unread?
  end

  def test_a_host_partial_for_the_kind_replaces_the_generic_detail
    get item_path_for(task("Write"))

    assert_select ".dummy-task-detail", 1
    assert_select ".bali-inbox-detail-generic", 0
  end

  def test_the_generic_detail_for_a_kind_without_a_partial
    document = Document.create!(title: "Policy", author_name: "Ana", status: :published)

    get item_path_for(document, kind: :acknowledgment)

    assert_select ".bali-inbox-detail-generic", /Policy/
  end

  def test_the_gone_body_is_the_same_whatever_the_reason
    done = task("Ship", status: :done)
    deleted = task("Gone").tap(&:destroy!)
    other_model = Document.create!(id: task("Pending").id + 1000, title: "Policy", author_name: "Ana")

    bodies = [ item_path_for(done), item_path_for(deleted), item_path_for(other_model),
               "/inbox/items/movie/#{done.to_gid_param}", "/inbox/items/task/garbage" ].map do |path|
      get path
      assert_response :success
      assert_select ".bali-inbox-gone", 1
      gone_pane
    end

    assert_equal 1, bodies.uniq.size
  end

  def test_open_item_marks_read_and_sends_to_its_href
    write = task("Write")
    notice = assigned(write)

    get "#{item_path_for(write)}/open"

    assert_redirected_to "/admin/projects/#{@project.id}"
    assert_response :see_other
    refute notice.reload.unread?
  end

  def test_open_item_on_a_stale_item_lands_on_gone
    get "#{item_path_for(task('Ship', status: :done))}/open"

    assert_redirected_to item_path_for(Task.last)
  end

  def test_open_notice_marks_it_read_and_follows_a_relative_action_url
    notice = released(action_url: "/admin/movies?status=done")

    get "/inbox/notices/#{notice.id}/open"

    assert_redirected_to "/admin/movies?status=done"
    refute notice.reload.unread?
  end

  def test_open_notice_never_leaves_the_site
    [ "https://evil.example/phish", "//evil.example/phish", "javascript:alert(1)" ].each do |url|
      get "/inbox/notices/#{released(action_url: url).id}/open"

      assert_redirected_to "/inbox?tab=notices", url
    end
  end

  def test_open_notice_for_someone_elses_notice_is_not_found
    get "/inbox/notices/#{released(recipient: @luis).id}/open"

    assert_response :not_found
  end

  def test_read_all_reads_every_unread_notice_of_the_owner_only
    mine = released
    theirs = released(recipient: @luis)

    post "/inbox/read_all"

    assert_redirected_to "/inbox?tab=notices"
    refute mine.reload.unread?
    assert theirs.reload.unread?
  end

  def test_read_all_from_the_popover_answers_a_turbo_stream_with_the_badge
    released

    post "/inbox/read_all", as: :turbo_stream

    assert_response :success
    assert_match %(target="#{Bali::Topbar::Inbox::Component::BADGE_FRAME_ID}"), response.body
    assert_match %(target="bali-inbox-popover-notices"), response.body
  end

  def test_the_popover_shows_at_most_ten_and_marks_the_folded_one_new
    11.times { |n| task("Task #{n}") }
    assigned(Task.first)

    get "/inbox/popover"

    assert_response :success
    assert_select "turbo-frame#bali-inbox-popover"
    assert_select ".bali-inbox-popover-row", 10
    assert_select ".bali-inbox-popover-row.is-fresh", 1
    assert_select ".bali-inbox-popover-row.is-fresh", /#{I18n.t("bali_view.inbox.fresh")}/
  end

  def test_the_popover_writes_the_live_numbers_to_the_icon
    task("Write")

    get "/inbox/popover"

    assert_match %(target="#{Bali::Topbar::Inbox::Component::BADGE_FRAME_ID}"), response.body
  end

  def test_the_popovers_notices_tab_leaves_out_what_announces
    released(message: "Alien is out")
    assigned(task("Write"))

    get "/inbox/popover", params: { tab: "notices" }

    assert_select ".bali-inbox-notice-message", 1
    assert_select ".bali-inbox-notice-message", "Alien is out"
  end

  def test_open_links_are_never_prefetched
    task("Write")
    released

    get "/inbox/popover"
    assert_select "a[href*='/open']:not([data-turbo-prefetch=false])", 0

    get "/inbox/popover", params: { tab: "notices" }
    assert_select "a[href*='/open']", minimum: 1
    assert_select "a[href*='/open']:not([data-turbo-prefetch=false])", 0
  end

  def test_without_an_owner_every_action_answers_401
    with_routing do |routes|
      routes.draw do
        resource :inbox, only: :show, controller: "inbox_request_test/ownerless_inboxes" do
          get :popover
        end
      end

      get "/inbox"
      assert_response :unauthorized

      get "/inbox/popover"
      assert_response :unauthorized
    end
  end

  # The host's own templates come first, so app/views/inboxes/show.html.erb replaces Bali's.
  def test_the_engine_views_sit_behind_the_controllers_own
    prefixes = InboxesController.new._prefixes

    assert_equal "inboxes", prefixes.first
    assert_equal "bali/inbox", prefixes.last
  end

  def test_the_badge_action_answers_the_badge_frame
    task("Write")

    get "/inbox/badge"

    assert_select "turbo-frame##{Bali::Topbar::Inbox::Component::BADGE_FRAME_ID} .bali-topbar-badge", "1"
  end
end
