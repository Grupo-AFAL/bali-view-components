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

        # Rows under a heading, with the group's own total beside it — the shape
        # both source listings have (gc groups by urgency, afal-apps by kind).
        # The rows move from `list.with_item` to `group.with_item`; nothing else
        # about a row changes.
        #
        #   <% @items.group_by(&:kind).each do |kind, rows| %>
        #     <% list.with_group(key: kind, label: t("inbox.kinds.#{kind}"),
        #                        count: @totals[kind]) do |group| %>
        #       <% rows.each do |item| %>
        #         <% group.with_item(id: item.id, href: ..., title: item.title) %>
        #       <% end %>
        #     <% end %>
        #   <% end %>
        #
        # **The listing has to be ordered by the group.** This is the one thing
        # grouping asks of the query, and it is not a style preference: infinite
        # scroll appends whole pages, so a listing ordered by anything else
        # scatters the same group across pages and the reader gets the same
        # heading three times. Ordered by the group, a page boundary can only
        # ever split ONE group — the last of a page and the first of the next —
        # and that is exactly the seam the controller merges. Written
        # `order(:kind, :created_at)`, the group key first.
        renders_many :groups, lambda { |**options, &block|
          Bali::SplitView::List::Group::Component.new(
            frame_id: @frame_id, selected_id: @selected, **options
          )
        }

        # Shown in place of the rows when there are none. Composed by the caller so the
        # two empty states a filtered listing needs (nothing yet / nothing matching)
        # stay the caller's words — see docs/guides/master-detail.md.
        renders_one :empty_state

        # The filter pills, in a band between the header and the rows — outside the
        # scroll area so they stay put while the rows move under them, inside the
        # card so they read as part of the listing.
        #
        #   <% list.with_filter(label: "Todas", href: inbox_path, active: bucket.nil?) %>
        #   <% list.with_filter(label: "Aprobaciones", count: 12,
        #                       href: inbox_path(bucket: "aprobaciones"),
        #                       active: bucket == "aprobaciones") %>
        #
        # Each one is a **link**, and the band is not a form: no submit button, no
        # clear button, no filtering machinery at all. That is what makes the rest
        # behave for free — a click is a full-page GET, so the server renders page
        # one, the infinite scroll resets, and the params ride into every page the
        # sentinel fetches next.
        #
        # Clearing is a URL, not a control: give the active pill an href without
        # its param and clicking it again drops the filter, or render an explicit
        # "all" pill pointing at the bare listing. Both are one ternary in the
        # caller, which is where the meaning of a param lives.
        renders_many :filters, lambda { |**options|
          Bali::SplitView::List::Filter::Component.new(mode: @filter_mode, **options)
        }

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
        # filter_mode - `:single` (default) for a bucket strip where one value is
        #             active at a time, `:multi` for pills that toggle independently
        #             over a multi-valued param. It only decides what a pill's URL
        #             does and how its state is announced; see
        #             Bali::SplitView::List::Filter::Component.
        def initialize(frame_id: nil, header: nil, count: nil, selected: nil, pagy: nil,
                       next_url: nil, infinite_scroll: true, item_name: nil, max_height: nil,
                       filter_mode: :single, **options)
          @frame_id = frame_id
          @header = header
          @count = count
          @selected = selected
          @pagy = pagy
          @next_url = next_url
          @infinite_scroll = infinite_scroll
          @item_name = item_name
          @max_height = max_height
          @filter_mode = filter_mode
          @options = options
        end

        def infinite_scroll? = @infinite_scroll && next_url.present?

        def grouped? = groups.any?

        # Whether the rows area has anything in it, which is what decides the
        # empty state. Asked of both slots because only one of them is ever used.
        def rows? = items.any? || grouped?

        # Mixing them renders the loose rows above the first heading, where they
        # belong to no group and the reader cannot tell why. It is always a
        # caller mistake, and a silent one, so it is named here instead.
        def before_render
          # The block that fills the slots has not run yet at this point —
          # ViewComponent leaves `content` unevaluated until the template asks for
          # it — so asking for it here is what makes `items` and `groups` true.
          content
          return unless items.any? && grouped?

          raise ArgumentError,
                "with_list takes `with_item` or `with_group`, not both: #{items.size} loose " \
                "row(s) alongside #{groups.size} group(s) would render above the first heading, " \
                "outside every group. Put every row in a group, or none."
        end

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
          attributes = options.except(:class, :data).merge(
            id: dom_id,
            class: class_names("split-view-list", options[:class])
          )
          return attributes.merge(data: options[:data]).compact unless infinite_scroll?

          # Merged into the host's `data:` and not over it: replacing the hash
          # dropped a caller's `data: { testid: }` — and only on the pages that
          # had a next one, so it came and went with the pagination.
          attributes.merge(
            data: (options[:data] || {}).merge(
              controller: "split-view-list",
              split_view_list_next_url_value: next_url,
              split_view_list_rows_id_value: dom_id
            )
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
