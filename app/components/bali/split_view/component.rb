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

      # `collapsible:` only: what the pane shows while the frame fetches a
      # detail, in place of the default spinner and «Loading…». It sits inside
      # the pane's `role="status"` region, so its text is announced.
      renders_one :loading

      DEFAULT_MASTER_WIDTH = "420px"

      HEIGHTS = %i[content full screen].freeze

      # A single CSS length or percentage. Anything more expressive (`minmax()`,
      # `clamp()`) belongs in the host's own stylesheet overriding
      # `--bali-split-master-width`, not in an inline style attribute built from
      # a Ruby argument. `master_width: :equal` is the one keyword.
      MASTER_WIDTH_FORMAT = /\A\d+(\.\d+)?(px|rem|em|ch|vw|%)\z/

      # A fixed `height:`: the same shape, with the viewport-height units.
      HEIGHT_FORMAT = /\A\d+(\.\d+)?(px|rem|em|vh|dvh|svh|lvh|%)\z/

      attr_reader :frame_id, :master_width

      # frame_id  - id of the detail Turbo Frame. Rows target it with
      #             `data-turbo-frame`, so it has to be unique in the page.
      # master_width - width of the master column from `lg` up. CSS length or
      #             percentage; drives `--bali-split-master-width`. `:equal`
      #             makes the two columns the same width to the pixel, the gap
      #             included (change that gap with `--bali-split-gap`, not a
      #             `gap-*` utility, or the halves stop matching).
      # height    - `:content` (default) lets the split grow with its content and
      #             the page scroll do the work. `:full` makes it fill the nearest
      #             ancestor with a definite height and gives EACH pane its own
      #             scrollbar — the inbox shape. It is `height: 100%` and a flex
      #             chain, nothing measured: with no bounded ancestor there is
      #             nothing to fill, so pair it with
      #             `Bali::AppLayout::Component.new(viewport_locked: true)`.
      #             Only from `lg` up; stacked panes cannot both fill one screen,
      #             so below that the page scrolls as usual.
      #             `:screen` fills from the split's top edge to the bottom of
      #             the viewport (`dvh`, kept right as the page above it changes),
      #             less the host's `--bali-split-bottom` (0 by default: the room
      #             its page keeps below), never shorter than `--bali-split-min-h`
      #             (28rem). A CSS length
      #             (`"640px"`, `"40rem"`, `"70vh"`) is a fixed height. Both give
      #             each pane the whole height, as `:full` does, and both apply
      #             from `lg` up: below it the panes stack as with `:content` (a
      #             `collapsible:` detail is a full-screen sheet there anyway).
      # advance   - emit `data-turbo-action="advance"` on the frame so a row click
      #             pushes its URL into the history and the selection is
      #             deep-linkable. Turn it off for a split view that is not a
      #             navigable location of its own.
      # frame_options - HTML attributes for the detail `<turbo-frame>`, as the
      #             remaining options are for the container. `class:` joins the
      #             component's; `data:` is merged into it key by key, so the
      #             `turbo_action` of `advance:` stays unless you name one, which
      #             wins; `id:` raises, because it is `frame_id:`.
      #             Nothing inside the detail can stand in for it: Turbo reads
      #             `data-autoscroll-block` and `data-autoscroll-behavior` off the
      #             frame already in the page, never off the one in the response.
      # collapsible - the master takes the whole width while there is no detail;
      #             a detail arriving (a Turbo Frame load, or anything the app
      #             puts in the frame) slides in from the right as the master
      #             shrinks, and «Close» or Esc slide it out and empty it.
      #             Below `lg` the detail covers the master, with «Back». The
      #             container emits `split-view:open` and `split-view:close`.
      #             A frame fetch opens the pane at once with a loading state
      #             (the `loading` slot replaces it), and a failed one shows an
      #             error with «Retry»; Close or Esc while it loads cancel the
      #             fetch. Off by default: without it nothing changes.
      def initialize(frame_id:, master_width: DEFAULT_MASTER_WIDTH, advance: true,
                     height: :content, frame_options: {}, collapsible: false, **options)
        @frame_id = frame_id
        @master_width = validated_master_width(master_width)
        @advance = advance
        @height = validated_height(height)
        @frame_options = validated_frame_options(frame_options)
        @collapsible = collapsible
        @options = options
      end

      private

      attr_reader :options, :frame_options

      def advance? = @advance
      def equal_width? = @master_width == :equal
      def screen_height? = @height == :screen
      def fixed_height? = @height.is_a?(String)
      # Every height that is not the content's own: each pane takes all of it.
      def filled_height? = @height != :content
      def collapsible? = !!@collapsible

      # Raises rather than falling back, like `master_width:` two lines up. A
      # silent fallback on the option that IS this feature turns `height: :fill`
      # into a component that renders the default and says nothing — and the
      # symptom (a split that does not fill) is exactly what a reader would go
      # hunting for in the CSS. Free to demand now, breaking to demand later.
      def validated_height(value)
        return value.strip if value.is_a?(String) && value.strip.match?(HEIGHT_FORMAT)

        height = value.is_a?(Symbol) || value.is_a?(String) ? value.to_sym : nil
        return height if HEIGHTS.include?(height)

        raise ArgumentError,
              "height must be one of #{HEIGHTS.map(&:inspect).join(', ')} or a CSS length " \
              "(e.g. \"640px\", \"40rem\", \"70vh\"), got #{value.inspect}."
      end

      def validated_frame_options(value)
        value = value.to_h.symbolize_keys
        return value unless value.key?(:id)

        raise ArgumentError,
              "frame_options cannot set id: the frame's id is frame_id:, which the rows and the controller target."
      end

      def validated_master_width(value)
        return :equal if value.to_s == "equal"

        width = value.to_s.strip
        return width if width.match?(MASTER_WIDTH_FORMAT)

        raise ArgumentError,
              "master_width must be :equal or a CSS length or percentage (e.g. \"420px\", \"24rem\", \"30%\"), " \
              "got #{value.inspect}. " \
              "For anything more expressive, override --bali-split-master-width in your own stylesheet."
      end

      def container_attributes
        options.merge(
          class: class_names("split-view-component",
                             ("split-view-component--full" if filled_height?),
                             ("split-view-component--screen" if screen_height?),
                             ("split-view-component--fixed" if fixed_height?),
                             ("split-view-component--equal" if equal_width?),
                             ("split-view-component--collapsible" if collapsible?),
                             options[:class]),
          data: options[:data].to_h.merge(controller_data),
          # The only inline declarations are the custom properties the CSS
          # reads: `lg:grid-cols-[#{master_width}_1fr]` would be an arbitrary
          # value Tailwind never sees at build time, so it would be purged out
          # of the bundle. `:equal` is a class instead (index.css).
          style: [ ("--bali-split-master-width: #{master_width}" unless equal_width?),
                   ("--bali-split-height: #{@height}" if fixed_height?),
                   options[:style] ].compact.join("; ")
        )
      end

      # The controllers the options need, beside the caller's own.
      def controller_data
        controllers = [ ("split-view-collapse" if collapsible?), ("split-view-screen" if screen_height?) ].compact
        return {} if controllers.empty?

        { controller: class_names(*controllers, options.dig(:data, :controller)) }.merge(collapsible_data)
      end

      # The collapse controller, and the state it starts in: open when the
      # server already rendered a detail (a deep link), closed otherwise.
      def collapsible_data
        return {} unless collapsible?

        { split_state: detail? ? "open" : "closed" }
      end

      def frame_attributes
        frame_options.merge(
          id: frame_id,
          class: class_names("split-view-detail", frame_options[:class]),
          # Keyed as Rails writes the attribute, `data-` and the key dasherized:
          # `turbo_action`, `"turbo_action"` and `"turbo-action"` are one attribute
          # in the HTML, but three keys here, which would render it twice and leave
          # the browser keeping the first — advance's.
          data: { "turbo-action" => ("advance" if advance?),
                  "split-view-collapse-target" => ("frame" if collapsible?) }
                  .merge(frame_options[:data].to_h.transform_keys { |key| key.to_s.dasherize })
        )
      end
    end
  end
end
