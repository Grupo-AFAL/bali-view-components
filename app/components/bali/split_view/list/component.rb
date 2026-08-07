# frozen_string_literal: true

module Bali
  module SplitView
    module List
      # The opinionated half of SplitView: the master listing.
      #
      # `with_list` + `with_item` exist so the four attributes that make a row work
      # — `data-turbo-frame`, `data-split-view-target`, `data-action` and
      # `aria-current` — stop being copied into every host template. The detail pane
      # stays completely free, and so does the `master` slot, which is still there for
      # a listing this shape does not fit.
      #
      #   <%= render Bali::SplitView::Component.new(frame_id: "inbox-detail") do |split| %>
      #     <% split.with_list(header: t("inbox.title"), count: @pagy.count,
      #                        selected: params[:selected], pagy: @pagy) do |list| %>
      #       <% @items.each do |item| %>
      #         <% list.with_item(id: item.id, href: inbox_path(selected: item.id),
      #                           title: item.title, subtitle: item.subtitle,
      #                           icon: item.icon, meta: l(item.due_on, format: :short),
      #                           meta_color: (:error if item.overdue?)) do |row| %>
      #           <% row.with_tag(text: item.kind_label, color: :info) %>
      #         <% end %>
      #       <% end %>
      #     <% end %>
      #   <% end %>
      #
      # **Selection is decided here, once.** `selected:` takes the id of the selected
      # record and each item its own `id:`; the component compares them. A host that
      # wrote `aria-current` per row was writing the same comparison N times.
      #
      # **Paging is infinite by default.** Given a `pagy:`, the list renders classic
      # pagination controls and a sentinel; the `split-view-list` controller hides the
      # controls on connect and loads the next page as the sentinel comes into view.
      # Without JavaScript the controls are what a reader gets, which is why they are
      # rendered rather than replaced.
      class Component < ApplicationViewComponent
        HEADER_CLASSES = "flex items-center gap-2 px-4 py-3 border-b border-b-base-200 " \
                         "text-sm font-medium"

        renders_many :items, lambda { |**options, &block|
          Bali::SplitView::List::Item::Component.new(
            frame_id: @frame_id, selected_id: @selected, **options
          )
        }

        # Shown in place of the rows when there are none. Composed by the caller so the
        # two empty states a filtered listing needs (nothing yet / nothing matching)
        # stay the caller's words — see docs/guides/master-detail.md.
        renders_one :empty_state

        attr_reader :header, :count, :pagy

        # frame_id is injected by the SplitView; a caller never passes it.
        #
        # selected  - id of the selected record, compared against each item's `id:`.
        # pagy      - Pagy object. Drives both the no-JS controls and the next page the
        #             sentinel loads.
        # next_url  - explicit next page, for a listing that pages without Pagy. Wins
        #             over the one derived from `pagy`.
        # infinite_scroll - false leaves the pagination controls alone and mounts no
        #             observer, for a listing short enough that paging is a click.
        # max_height - value for `--bali-split-master-max-h` on the scroll area.
        def initialize(frame_id: nil, header: nil, count: nil, selected: nil, pagy: nil,
                       next_url: nil, infinite_scroll: true, item_name: nil, max_height: nil,
                       **options)
          @frame_id = frame_id
          @header = header
          @count = count
          @selected = selected
          @pagy = pagy
          @next_url = next_url
          @infinite_scroll = infinite_scroll
          @item_name = item_name
          @max_height = max_height
          @options = options
        end

        def infinite_scroll? = @infinite_scroll && next_url.present?

        # Where the sentinel fetches the next rows from. Derived through the same
        # adapter `Bali::Pagination` builds its links with, so a listing does not need
        # Pagy's own URL helpers in scope.
        def next_url
          return @next_url if @next_url.present?
          return nil if pagy.nil?

          adapter = Bali::Pagination::PagyAdapter.new(pagy)
          adapter.next_page && adapter.page_url(adapter.next_page)
        end

        def paginated? = pagy.present? && pagy.pages > 1

        private

        attr_reader :options

        def dom_id = [ @frame_id, "list" ].compact.join("-")

        def container_attributes
          attributes = options.except(:class).merge(
            id: dom_id,
            class: class_names("split-view-list", options[:class])
          )
          return attributes unless infinite_scroll?

          attributes.merge(
            data: {
              controller: "split-view-list",
              split_view_list_next_url_value: next_url,
              split_view_list_rows_id_value: dom_id
            }
          )
        end

        def scroll_attributes
          { class: "split-view-scroll", data: { split_view_list_target: "scroller" } }.tap do |a|
            a[:style] = "--bali-split-master-max-h: #{@max_height}" if @max_height.present?
          end
        end

        # nil on purpose: PaginationFooter already has a default, and inventing a
        # second one here would only make the two disagree.
        def item_name = @item_name.presence
      end
    end
  end
end
