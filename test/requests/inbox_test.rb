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

  def test_show_renders_the_pending_tab_with_its_bands_pills_and_counts
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

  # Beside the tabs, not on a row of its own above the list: it scopes «Pendientes» alone.
  def test_the_module_filter_sits_on_the_tab_row_of_the_pending_tab_only
    task("Ship it")

    get "/inbox"
    assert_select ".bali-inbox-tabs [data-controller~='dropdown']" do
      assert_select ".sr-only", text: I18n.t("bali_view.inbox.modules.all")
    end

    get "/inbox", params: { tab: "notices" }
    assert_select ".bali-inbox [data-controller~='dropdown']", false
  end

  # A square trigger is sized for an icon: the text spilled out of it and the icon over «Open».
  def test_the_copy_link_button_is_sized_for_its_text_and_named_by_it
    get item_path_for(task("Ship it"))

    trigger = css_select(".bali-inbox-detail .clipboard-trigger").sole
    assert_not_includes trigger["class"].split, "btn-square"
    assert_equal I18n.t("bali_view.inbox.detail.copy"), trigger["aria-label"]
    assert_equal "true", css_select(".bali-inbox-detail .clipboard-source").sole["aria-hidden"],
                 "a screen reader would read the whole URL, gid and all"
  end

  # The list is a card, so the pane beside it is one too, whatever it holds.
  def test_the_detail_pane_sits_in_a_card_like_the_list
    get "/inbox"
    assert_select "#bali-inbox-detail > .card .empty-state-component"

    get item_path_for(task("Ship it"))
    assert_select "#bali-inbox-detail > .card .bali-inbox-detail"

    get item_path_for(task("Done", status: :done))
    assert_select "#bali-inbox-detail > .card .bali-inbox-gone"
  end

  def test_every_kind_of_stale_address_gets_the_same_gone_detail
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
    [ "https://evil.example/phish", "//evil.example/phish", "/\\evil.example/phish", "javascript:alert(1)",
      "/a path with spaces" ].each do |url|
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

  # The whole popover again, on «Avisos»: the list and that tab's title lose their unread count,
  # and the icon its dot.
  def test_read_all_from_the_popover_re_renders_it_on_the_notices_tab
    released

    post "/inbox/read_all", params: { from: "popover" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match %(target="#{Bali::Topbar::Inbox::Component::POPOVER_FRAME_ID}"), response.body
    assert_match %(target="#{Bali::Topbar::Inbox::Component::BADGE_FRAME_ID}"), response.body
    assert_select "[role=tab]#bali-inbox-tab-1", /\A\s*#{I18n.t("bali_view.inbox.tabs.notices")}\s*\z/
  end

  # Turbo asks a form for a stream first; the page's still has to land back on the page.
  def test_read_all_from_the_page_redirects_even_when_the_request_takes_a_stream
    post "/inbox/read_all", as: :turbo_stream

    assert_redirected_to "/inbox?tab=notices"
  end

  def test_the_popover_shows_at_most_ten_and_marks_the_folded_one_new
    11.times { |n| task("Task #{n}") }
    assigned(Task.first)

    get "/inbox/popover"

    assert_response :success
    assert_select "turbo-frame#bali-inbox-popover"
    assert_select ".bali-inbox-popover-row", 10
    assert_select ".bali-inbox-popover-row.is-fresh", 1
    assert_select ".bali-inbox-popover-row.is-fresh .bali-inbox-popover-dot.bg-primary", 1
    assert_select ".bali-inbox-popover-dot", 1
    assert_select ".bali-inbox-popover-row.is-fresh .sr-only", ", #{I18n.t("bali_view.inbox.fresh")}"
    assert_select ".bali-inbox-popover-row .badge", 0
  end

  # Both tabs the same shape: the name, and its number in the pill Bali::Tabs draws. The notices'
  # counts only the unread ones, which a screen reader hears.
  def test_each_popover_tab_carries_its_number
    task("Write")
    released

    get "/inbox/popover"

    unread = I18n.t("bali_view.inbox.notices.unread")
    assert_select "[role=tab]#bali-inbox-tab-0", /\A\s*#{I18n.t("bali_view.inbox.tabs.pending")}\s*1\s*\z/
    assert_select "[role=tab]#bali-inbox-tab-1", /\A\s*#{I18n.t("bali_view.inbox.tabs.notices")}\s*1 #{unread}\s*\z/
    assert_select "[role=tab]#bali-inbox-tab-1 .badge .sr-only", unread
  end

  # In `es`, whose number format in the dummy writes 13.887, as rails-i18n's does in some hosts.
  def test_the_pending_number_is_written_with_a_thousands_comma
    count = Bali::Inbox::Query.instance_method(:count)
    task("Write")
    Bali::Inbox::Query.define_method(:count) { 13_887 }

    get "/inbox/popover", params: { locale: "es" }

    assert_select "[role=tab]#bali-inbox-tab-0 .badge", "13,887"
    assert_match I18n.t("bali_view.inbox.footer.pending", count: 13_887, number: "13,887", locale: :es), response.body
  ensure
    Bali::Inbox::Query.define_method(:count, count)
  end

  def test_the_pages_tabs_and_kind_pills_carry_their_numbers_with_a_thousands_comma
    counts = Bali::Inbox::Query.instance_method(:counts_by_kind)
    task("Write")
    released
    Bali::Inbox::Query.define_method(:counts_by_kind) { { task: 13_887 } }

    get "/inbox", params: { locale: "es" }

    tabs = css_select(".bali-inbox-tabs a.tab")
    assert_equal "13,887", tabs.first.at_css(".badge")&.text
    assert_equal "1 #{I18n.t("bali_view.inbox.notices.unread", locale: :es)}", tabs.last.at_css(".badge")&.text
    assert_select ".split-view-filter-count", text: "13,887", count: 2
  ensure
    Bali::Inbox::Query.define_method(:counts_by_kind, counts)
  end

  def test_the_popovers_tabs_use_ids_of_their_own
    get "/inbox/popover"

    assert_select "[role=tab]#bali-inbox-tab-0[aria-controls=bali-inbox-tabpanel-0]"
    assert_select "#tab-0, #tabpanel-0", 0
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

  # Every GET that marks something read: the open links, and the page's rows, which load the
  # item's detail (`item` reads its folded notices). Turbo prefetches a frame link too.
  def test_no_link_that_marks_read_is_ever_prefetched
    assigned(task("Write"))
    released

    get "/inbox/popover"
    assert_select "a[href*='/open']", minimum: 1
    assert_select "a[href*='/open']:not([data-turbo-prefetch=false])", 0

    get "/inbox/popover", params: { tab: "notices" }
    assert_select "a[href*='/open']", minimum: 1
    assert_select "a[href*='/open']:not([data-turbo-prefetch=false])", 0

    get "/inbox"
    assert_select "a[href*='/inbox/items/']", minimum: 1
    assert_select "a[href*='/inbox/items/']:not([data-turbo-prefetch=false])", 0
  end

  def test_without_an_owner_every_action_answers_401
    with_routing do |routes|
      routes.draw do
        resource :inbox, only: :show, controller: "inbox_request_test/ownerless_inboxes" do
          get :popover
          get :badge
          get "items/:kind/:gid", action: :item
          get "items/:kind/:gid/open", action: :open_item
          get "notices/:id/open", action: :open_notice
          post :read_all
        end
      end

      gid = task("Write").to_gid_param
      [ [ :get, "/inbox" ], [ :get, "/inbox/popover" ], [ :get, "/inbox/badge" ],
        [ :get, "/inbox/items/task/#{gid}" ], [ :get, "/inbox/items/task/#{gid}/open" ],
        [ :get, "/inbox/notices/#{released.id}/open" ], [ :post, "/inbox/read_all" ] ].each do |verb, path|
        send(verb, path)

        assert_response :unauthorized, "#{verb.upcase} #{path}"
      end
    end
  end

  # bali-auth's helper, private on the controller: the owner is who the request acts as, and an
  # admin is behind it.
  def impersonating
    InboxesController.class_eval { private def impersonating? = true }
    yield
  ensure
    InboxesController.remove_method(:impersonating?)
  end

  def test_while_impersonating_viewing_an_item_leaves_its_notice_unread
    write = task("Write")
    folded = assigned(write)

    impersonating { get item_path_for(write) }

    assert_response :success
    assert folded.reload.unread?
  end

  def test_while_impersonating_opening_an_item_leaves_its_notice_unread
    write = task("Write")
    folded = assigned(write)

    impersonating { get "#{item_path_for(write)}/open" }

    assert_redirected_to "/admin/projects/#{@project.id}"
    assert folded.reload.unread?
  end

  def test_while_impersonating_opening_a_notice_leaves_it_unread
    notice = released(action_url: "/admin/movies")

    impersonating { get "/inbox/notices/#{notice.id}/open" }

    assert_redirected_to "/admin/movies"
    assert notice.reload.unread?
  end

  def test_while_impersonating_read_all_is_not_offered_and_reads_nothing
    notice = released
    get "/inbox/popover", params: { tab: "notices" }
    assert_select "form[action*='read_all']", count: 1

    impersonating do
      get "/inbox/popover", params: { tab: "notices" }
      assert_response :success
      assert_select "form[action*='read_all']", count: 0
      get "/inbox", params: { tab: "notices" }
      assert_select "form[action*='read_all']", count: 0
      post "/inbox/read_all"
    end

    assert_redirected_to "/inbox?tab=notices"
    assert notice.reload.unread?
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
