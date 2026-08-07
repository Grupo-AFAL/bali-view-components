# frozen_string_literal: true

require "test_helper"

# The structured listing exists to stop hosts writing the row wiring by hand, so
# most of what is worth asserting here is the wiring it writes for them.
class BaliSplitViewListComponentTest < ComponentTestCase
  def render_list(list_options = {}, items: [ { id: 1, title: "First", href: "/inbox?selected=1" } ])
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_list(**list_options) do |list|
        items.each { |item| list.with_item(**item) }
      end
    end
  end

  # --- the wiring, which is the whole point -------------------------------------------

  def test_row_carries_the_frame_the_split_view_declared
    render_list
    assert_selector('.split-view-item[data-turbo-frame="inbox-detail"]')
  end

  def test_row_carries_the_controller_target_and_action
    render_list
    assert_selector('.split-view-item[data-split-view-target="row"]')
    assert_selector('.split-view-item[data-action="click->split-view#select"]')
  end

  # The frame is what `advance:` controls; a link-level one would silently beat it.
  def test_row_does_not_carry_a_turbo_action_of_its_own
    render_list
    assert_no_selector(".split-view-item[data-turbo-action]")
  end

  def test_row_is_a_link_to_its_href_and_keeps_the_row_class
    render_list
    assert_selector('a.split-view-row.split-view-item[href="/inbox?selected=1"]')
  end

  def test_row_gets_a_dom_id_derived_from_the_frame_and_its_own_id
    render_list
    assert_selector("a#inbox-detail-item-1")
  end

  # --- selection is decided once, by the list ------------------------------------------

  def test_the_matching_item_is_marked_current_and_no_other
    render_list(
      { selected: 2 },
      items: [
        { id: 1, title: "First", href: "/inbox?selected=1" },
        { id: 2, title: "Second", href: "/inbox?selected=2" },
        { id: 3, title: "Third", href: "/inbox?selected=3" }
      ]
    )

    assert_selector('.split-view-item[aria-current="true"]', count: 1)
    assert_selector('a#inbox-detail-item-2[aria-current="true"]')
  end

  # Ids arrive from params as Strings and from records as Integers.
  def test_selection_compares_ids_across_types
    render_list({ selected: "1" })
    assert_selector('a#inbox-detail-item-1[aria-current="true"]')
  end

  def test_nothing_is_current_without_a_selection
    render_list
    assert_no_selector(".split-view-item[aria-current]")
  end

  def test_an_item_without_an_id_is_never_current
    render_list({ selected: 1 }, items: [ { title: "First", href: "/inbox?selected=1" } ])
    assert_no_selector(".split-view-item[aria-current]")
  end

  # --- the fields, as taken from the two listings this generalises ---------------------

  def test_renders_title_subtitle_icon_tags_and_meta
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_list do |list|
        list.with_item(id: 1, title: "Contract", href: "/x", subtitle: "Legal",
                       icon: "file-text", meta: "12 Aug") do |row|
          row.with_tag(text: "Approval", color: :info)
          row.with_tag(text: "Urgent", color: :error)
        end
      end
    end

    assert_selector(".split-view-item", text: "Contract")
    assert_selector(".split-view-item", text: "Legal")
    assert_selector(".split-view-item svg")
    assert_selector(".split-view-item .badge", count: 2)
    assert_selector(".split-view-item", text: "12 Aug")
  end

  def test_meta_color_paints_the_overdue_case
    render_list({}, items: [ { id: 1, title: "T", href: "/x", meta: "1 Jan", meta_color: :error } ])
    assert_selector(".split-view-item .text-error", text: "1 Jan")
  end

  def test_meta_is_neutral_without_a_color
    render_list({}, items: [ { id: 1, title: "T", href: "/x", meta: "1 Jan" } ])
    assert_selector(".split-view-item .text-base-content\\/60", text: "1 Jan")
  end

  def test_free_block_content_renders_inside_the_row
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_list do |list|
        list.with_item(id: 1, title: "T", href: "/x") { "EXTRA ROW CONTENT" }
      end
    end

    assert_selector(".split-view-item", text: "EXTRA ROW CONTENT")
  end

  # --- header and empty state -----------------------------------------------------------

  def test_header_and_count_render
    render_list({ header: "Inbox", count: 42 })
    assert_selector(".split-view-list", text: "Inbox")
    assert_selector('[data-testid="list-count"]', text: "42")
  end

  def test_empty_state_replaces_the_rows_when_there_are_none
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_list do |list|
        list.with_empty_state { "NOTHING HERE" }
      end
    end

    assert_selector(".split-view-list", text: "NOTHING HERE")
    assert_no_selector(".split-view-item")
  end

  # --- paging ---------------------------------------------------------------------------

  def pagy(page: 1, count: 30, limit: 10)
    request = Pagy::Request.new(
      request: { base_url: "http://example.com", path: "/inbox", params: {}, cookie: nil }
    )
    Pagy::Offset.new(count: count, page: page, limit: limit, request: request)
  end

  def test_pagination_controls_render_for_the_reader_without_javascript
    render_list({ pagy: pagy })
    assert_selector('[data-split-view-list-target="pagination"]')
    assert_selector('[data-split-view-list-target="pagination"] a', minimum: 1)
  end

  def test_the_sentinel_and_the_next_url_come_from_the_pagy
    render_list({ pagy: pagy })
    assert_selector('[data-controller="split-view-list"]')
    assert_selector('[data-split-view-list-next-url-value*="page=2"]')
    assert_selector('[data-split-view-list-target="sentinel"]', visible: :all)
  end

  # Nothing left to fetch: no controller, no sentinel. The classic controls stay,
  # because a reader who deep-linked to the last page still needs to go back.
  def test_the_last_page_mounts_no_infinite_scroll
    render_list({ pagy: pagy(page: 3) })
    assert_no_selector('[data-controller="split-view-list"]')
    assert_no_selector('[data-split-view-list-target="sentinel"]', visible: :all)
    assert_selector('[data-split-view-list-target="pagination"]')
  end

  def test_infinite_scroll_false_leaves_the_controls_alone
    render_list({ pagy: pagy, infinite_scroll: false })
    assert_no_selector('[data-controller="split-view-list"]')
    assert_selector('[data-split-view-list-target="pagination"]')
  end

  def test_an_explicit_next_url_wins_over_the_pagy
    render_list({ pagy: pagy, next_url: "/custom?cursor=abc" })
    assert_selector('[data-split-view-list-next-url-value="/custom?cursor=abc"]')
  end

  def test_next_url_alone_drives_infinite_scroll_without_a_pagy
    render_list({ next_url: "/custom?cursor=abc" })
    assert_selector('[data-controller="split-view-list"]')
    assert_no_selector('[data-split-view-list-target="pagination"]')
  end

  # The controller extracts rows out of the fetched page by this id, so the two
  # have to be the same string on every page of the same listing.
  def test_the_rows_id_the_controller_looks_for_is_the_list_id
    render_list({ next_url: "/x?page=2" })
    assert_selector('#inbox-detail-list[data-split-view-list-rows-id-value="inbox-detail-list"]')
    assert_selector('#inbox-detail-list [data-split-view-list-target="rows"]')
  end

  def test_max_height_reaches_the_scroll_area_as_a_custom_property
    render_list({ max_height: "26rem" })
    assert_selector('[data-split-view-list-target="scroller"][style*="--bali-split-master-max-h: 26rem"]')
  end

  # The sentinel's three strings ship translated and WITHOUT a `default:`. The
  # defaults were what hid the fact that the scope did not exist at all: they
  # rendered, in Spanish, for every host on earth, and nothing failed. Parity
  # between the two locale files is `BaliI18nScopeTest`'s job; that the keys are
  # there in the first place is this one's.
  def test_the_sentinel_strings_are_translated_in_every_locale
    keys = %w[end_of_list load_error retry]

    I18n.available_locales.each do |locale|
      keys.each do |key|
        assert I18n.exists?("bali_view.split_view.#{key}", locale),
          "falta bali_view.split_view.#{key} en #{locale}"
      end
    end
  end

  def test_the_sentinel_renders_no_missing_translation
    render_list({ next_url: "/x?page=2" })
    assert_no_text(/translation missing/i)
  end

  # --- host attributes survive ------------------------------------------------------------

  # Merging and not replacing: the previous version dropped a caller's `data:`,
  # and only while there was a next page — so it came and went with the paging.
  def test_a_host_data_attribute_survives_infinite_scroll
    render_list({ next_url: "/x?page=2", data: { testid: "inbox-list" } })
    assert_selector('.split-view-list[data-testid="inbox-list"]')
    assert_selector('.split-view-list[data-controller="split-view-list"]')
  end

  def test_a_host_data_attribute_survives_without_infinite_scroll
    render_list({ data: { testid: "inbox-list" } })
    assert_selector('.split-view-list[data-testid="inbox-list"]')
    assert_no_selector(".split-view-list[data-controller]")
  end

  # --- the escape hatch is untouched ------------------------------------------------------

  def test_the_free_master_slot_still_renders
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "HAND ROLLED" }
    end

    assert_selector('.split-view-master[data-controller="split-view"]', text: "HAND ROLLED")
    assert_no_selector(".split-view-list")
  end

  def test_the_list_wins_when_both_slots_are_given
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "HAND ROLLED" }
      split.with_list { |list| list.with_item(id: 1, title: "Structured", href: "/x") }
    end

    assert_selector(".split-view-list", text: "Structured")
    assert_no_text("HAND ROLLED")
  end

  def test_the_list_sits_inside_the_split_view_controller_element
    render_list
    assert_selector('.split-view-master[data-controller="split-view"] .split-view-list')
  end
end
