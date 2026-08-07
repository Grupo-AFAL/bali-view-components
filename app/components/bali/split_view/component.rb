# frozen_string_literal: true

module Bali
  module SplitView
    # Master-detail layout (the "inbox" shape): a list on the left, the detail of
    # the selected row on the right inside a Turbo Frame, so clicking a row swaps
    # only the detail pane — the master keeps its scroll position and its
    # highlight without a re-render.
    #
    # The component is deliberately thin. It owns the three things that are
    # identical in every master-detail screen — the responsive grid, the frame,
    # and the row-highlight controller — and nothing else. Tabs, filter chips,
    # pagination and the rows themselves are content: they go inside the `master`
    # slot in whatever shape the screen needs.
    #
    #   <%= render Bali::SplitView::Component.new(frame_id: "inbox-detail") do |split| %>
    #     <% split.with_master do %>
    #       <%= render "master_pane", items: @items, selected: @selected %>
    #     <% end %>
    #     <% if @selected %>
    #       <% split.with_detail { render "detail_pane", item: @selected } %>
    #     <% else %>
    #       <% split.with_empty_detail do %>
    #         <%= render Bali::EmptyState::Component.new(title: "Selecciona un elemento") %>
    #       <% end %>
    #     <% end %>
    #   <% end %>
    #
    # Rows opt into the highlight with three data attributes and the
    # `split-view-row` class:
    #
    #   <%= link_to inbox_path(selected: item.id),
    #         class: "split-view-row",
    #         aria: { current: (item == @selected ? "true" : nil) },
    #         data: { turbo_frame: "inbox-detail",
    #                 split_view_target: "row",
    #                 action: "click->split-view#select" } do %>
    #
    # No `turbo_action:` on the row: `advance:` puts it on the frame, and a
    # link-level one wins over the frame's — so writing it here would silently
    # defeat `advance: false`.
    #
    # The server still paints the selection on first render and on full-page
    # navigation; the Stimulus controller only covers the in-page transitions.
    # Below `lg` the two panes stack (master on top), which needs no extra JS.
    class Component < ApplicationViewComponent
      # The structured listing, and the way to build a master. It writes the row
      # wiring itself — `data-turbo-frame`, `data-split-view-target`,
      # `data-action` and `aria-current` — and pages by infinite scroll when
      # given a `pagy:`. See Bali::SplitView::List::Component.
      renders_one :list, lambda { |**options, &block|
        Bali::SplitView::List::Component.new(frame_id: @frame_id, **options)
      }

      # Free-form left column: the escape hatch for a listing `list` does not
      # fit. Wrapped in the same `split-view` controller element, so rows written
      # by hand are still its targets — the two are interchangeable, not two
      # different components.
      renders_one :master

      # Initial contents of the frame — what the server renders for the current
      # selection.
      renders_one :detail

      # Shown inside the frame when there is no selection. Ignored when `detail`
      # is present.
      renders_one :empty_detail

      DEFAULT_MASTER_WIDTH = "420px"

      # A single CSS length or percentage. Anything more expressive (`minmax()`,
      # `clamp()`) belongs in the host's own stylesheet overriding
      # `--bali-split-master-width`, not in an inline style attribute built from
      # a Ruby argument.
      MASTER_WIDTH_FORMAT = /\A\d+(\.\d+)?(px|rem|em|ch|vw|%)\z/

      attr_reader :frame_id, :master_width

      # frame_id  - id of the detail Turbo Frame. Rows target it with
      #             `data-turbo-frame`, so it has to be unique in the page.
      # master_width - width of the master column from `lg` up. CSS length or
      #             percentage; drives `--bali-split-master-width`.
      # advance   - emit `data-turbo-action="advance"` on the frame so a row click
      #             pushes its URL into the history and the selection is
      #             deep-linkable. Turn it off for a split view that is not a
      #             navigable location of its own.
      def initialize(frame_id:, master_width: DEFAULT_MASTER_WIDTH, advance: true, **options)
        @frame_id = frame_id
        @master_width = validated_master_width(master_width)
        @advance = advance
        @options = options
      end

      private

      attr_reader :options

      def advance? = @advance

      def validated_master_width(value)
        width = value.to_s.strip
        return width if width.match?(MASTER_WIDTH_FORMAT)

        raise ArgumentError,
              "master_width must be a CSS length or percentage (e.g. \"420px\", \"24rem\", \"30%\"), got #{value.inspect}. " \
              "For anything more expressive, override --bali-split-master-width in your own stylesheet."
      end

      def container_attributes
        options.except(:class, :style)
               .merge(
                 class: class_names("split-view-component", options[:class]),
                 # The only inline declaration is the custom property the grid
                 # reads: `lg:grid-cols-[#{master_width}_1fr]` would be an
                 # arbitrary value Tailwind never sees at build time, so it would
                 # be purged out of the bundle.
                 style: [ "--bali-split-master-width: #{master_width}", options[:style] ].compact.join("; ")
               )
      end

      def frame_attributes
        { id: frame_id, class: "split-view-detail" }.tap do |attributes|
          attributes[:data] = { turbo_action: "advance" } if advance?
        end
      end
    end
  end
end
