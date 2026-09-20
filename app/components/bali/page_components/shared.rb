# frozen_string_literal: true

module Bali
  module PageComponents
    module Shared
      extend ActiveSupport::Concern

      include Bali::DataTable::ToolbarHref

      # ABSOLUTE keys: FIVE components include this concern, so `t('.x')` would resolve to
      # five different sidecar scopes and none of them would exist.
      SECONDARY_ACTIONS_LABEL_KEY = "bali_view.page_components.secondary_actions.button_label"
      EXPORT_MENU_TITLE_KEY = "bali_view.page_components.export.menu_title"

      # ONE width table for the five. It used to live duplicated in DashboardPage (four keys,
      # no `sm`/`md`) and in FormPage (five, no `2xl`), and the other three had no
      # `max_width:` at all — so the same symbol meant a different width depending on the
      # component, or nothing.
      MAX_WIDTHS = {
        sm: "max-w-xl",
        md: "max-w-3xl",
        lg: "max-w-5xl",
        xl: "max-w-7xl",
        "2xl": "max-w-screen-2xl",
        full: "max-w-full"
      }.freeze

      # The body + sidebar grid, parameterized. `:default` is the 2/3 + 1/3 that ShowPage and
      # FormPage had copied verbatim.
      SIDEBAR_WIDTHS = {
        narrow: { grid: "lg:grid-cols-4", main: "lg:col-span-3" },
        default: { grid: "lg:grid-cols-3", main: "lg:col-span-2" },
        wide: { grid: "lg:grid-cols-2", main: "lg:col-span-1" }
      }.freeze

      # The keyword args this concern keeps for itself. A component that also takes loose HTML
      # options (DocumentPage) splits them with `slice`/`except` over this list instead of
      # repeating the signature.
      PAGE_OPTIONS = %i[title subtitle breadcrumbs back max_width sidebar_width context
                        heading].freeze

      # Where the page is being rendered. `:auto` asks the request; the other two state it,
      # which is what lets a test or a Lookbook preview pin the variant without simulating a
      # drawer fetch, and what keeps the component a function of its arguments when the host
      # wants it to be.
      CONTEXTS = %i[auto page drawer].freeze

      # Valid levels for the page title. `nil` is not here because it is not a level: it
      # means "let the context decide" (see #heading).
      HEADINGS = %i[h1 h2 h3 h4 h5 h6].freeze

      # A single gap between the header (or the nav) and the body. It used to be `mt-4` in
      # IndexPage, `mt-6` in ShowPage/FormPage/DocumentPage and none at all in DashboardPage.
      BODY_SPACING_CLASS = "mt-6"

      included do
        renders_many :actions
        renders_many :title_tags
        renders_one :nav
        renders_one :body
        renders_one :sidebar

        # The default width is the ONLY thing that changes between the five: the table that
        # resolves it is the same. `full` for the ones that never had a container, so that
        # inheriting it does not change their layout.
        class_attribute :default_max_width, instance_writer: false, default: :full
      end

      # The shared signature of the five. A component that adds arguments of its own declares
      # them and calls `super` with the rest.
      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil, max_width: nil,
                     sidebar_width: :default, context: :auto, heading: nil)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @back = back
        @context = resolve_context(context)
        @heading = resolve_heading(heading)
        @max_width_key = (max_width || default_max_width).to_sym
        @max_width = MAX_WIDTHS.fetch(@max_width_key) do
          raise ArgumentError,
                "Unknown max_width: #{@max_width_key.inspect}. Valid: #{MAX_WIDTHS.keys.join(', ')}"
        end
        @sidebar_width = resolve_sidebar_width(sidebar_width)
      end

      # Whether this page is rendering as the contents of a Modal or a Drawer. Public, and
      # yielded with the component, because the host's own markup inside the body sometimes
      # has to follow: a Cancel that closes an overlay is not a Cancel that navigates away,
      # and no amount of page chrome can decide that for it.
      #
      # Memoised rather than computed in the constructor: `helpers` needs a view context,
      # which a component only has from `render` onwards.
      def drawer?
        return @drawer if defined?(@drawer)

        @drawer = context == :auto ? drawer_request? : context == :drawer
      end

      # The level of the page title: the fourth contextual axis, after `back:`, the
      # breadcrumbs and the Card. Same contract as `FormPage#card?`: `nil` —the default—
      # leaves the decision to the context, and an explicit value wins both ways. Inside a
      # drawer it drops to `h2` and not to `h3` because the page left underneath keeps its
      # `h1`: the panel follows the document hierarchy without skipping levels (#1055).
      def heading
        return @heading if @heading

        drawer? ? :h2 : :h1
      end

      # SECONDARY page actions: they live in the ⋯ next to the primary one. The ARGUMENTS are
      # stored rather than the already-rendered content because the ⋯ is a real
      # Bali::Dropdown and its items have to go through `with_item` to inherit the menuitem
      # role and the Link/DeleteLink selection. Same pattern as DashboardPage#with_stat.
      #
      # @param options [Hash] Bali::Dropdown#with_item options (href:, icon:,
      #   method:, tag:, authorized:)
      def with_secondary_action(**options, &block)
        secondary_action_items << [ options, block ]
        nil
      end

      # Export the listing. It lives here and not in the DataTable toolbar because exporting
      # is an action ON the page, not a control over how the listing looks — and that way
      # importing or printing have somewhere to land later. It is called "Export filtered"
      # because the link carries the active slice along (see
      # Bali::DataTable::Export::Component#export_url).
      #
      # @param url [String] Base URL of the listing (without `format`)
      # @param formats [Array<Symbol>] Formats to offer
      # @param params [Hash, nil] Slice to carry along. `nil` reads it from the request; `{}`
      #   is the explicit opt-out.
      def with_export(url:, formats: %i[csv excel pdf], params: nil)
        @export_options = { url: url, formats: formats, params: params }
        nil
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :max_width, :context

      # Breadcrumbs and the back button are the two ways OUT of a page, and a drawer is not a
      # page you leave — you close it. Both are therefore chrome the context owns, not values
      # the caller can rescue by passing them: the whole point is that ONE call site works in
      # both places, and the canonical call site passes `back:`. The escape hatch for a drawer
      # that genuinely wants page chrome is `context: :page`, which restores all of it.
      def back
        @back unless drawer?
      end

      def render_breadcrumbs?
        breadcrumbs.any? && !drawer?
      end

      # The component never reads `params`: it asks the host, through
      # `Bali::LayoutConcern#drawer_request?`. That indirection is the point — an app that
      # already declares a `drawer_request?` helper of its own, which is the very pattern this
      # replaces, is detected without touching a line of its controllers, and a view context
      # that declares no such helper (a Lookbook preview, a unit test) renders as a page.
      def drawer_request?
        helpers.respond_to?(:drawer_request?) && helpers.drawer_request?
      end

      def resolve_context(value)
        key = (value || :auto).to_sym
        return key if CONTEXTS.include?(key)

        raise ArgumentError,
              "Unknown context: #{value.inspect}. Valid: #{CONTEXTS.join(', ')}"
      end

      # The `to_sym` guard is not paranoia: `2` is plausible because levels are idiomatically
      # integers (aria-level), and `false` by analogy with `card: false` — and both deserve
      # the ArgumentError that names the valid values, not a NoMethodError.
      def resolve_heading(value)
        return if value.nil?

        key = value.respond_to?(:to_sym) ? value.to_sym : value
        return key if HEADINGS.include?(key)

        raise ArgumentError,
              "Unknown heading: #{value.inspect}. Valid: #{HEADINGS.join(', ')}"
      end

      def secondary_action_items
        @secondary_action_items ||= []
      end

      def secondary_actions?
        @export_options.present? || secondary_action_items.any?
      end

      def render_secondary_actions
        return unless secondary_actions?

        render(Bali::Dropdown::Component.new(
          direction: :bottom,
          align: :end,
          data: { controller: "export-links", export_links_sync_value: export_links_sync? }
        )) do |dropdown|
          # `ellipsis-vertical` and not `ellipsis`: below `sm` this menu and the toolbar's
          # overflow ⋯ end up right next to each other, and with the same icon they are two
          # identical buttons that open different things.
          #
          # No `btn-sm`: the ⋯ is a flex sibling of the primary action and shares its row, and
          # the small size left it 8px shorter than the button it is glued to. `sm` is the
          # size of the TOOLBAR controls, which is where this menu came from.
          dropdown.with_trigger(variant: :ghost, class: "btn-square",
                                "aria-label": I18n.t(SECONDARY_ACTIONS_LABEL_KEY)) do
            render Bali::Icon::Component.new("ellipsis-vertical", class: "w-5 h-5")
          end
          export_menu_items.each { |item| dropdown.with_item(**item) }
          secondary_action_items.each { |options, block| dropdown.with_item(**options, &block) }
        end
      end

      # The section heading is what NAMES the action ("Export filtered"); the formats go
      # underneath it. With one item per format and no title the menu would read "CSV /
      # Excel / PDF" and nobody would know what of.
      #
      # The title also goes as `aria-describedby` on each format: inside a
      # `<ul role="menu">` the screen reader navigates ONLY the menuitems —the same way
      # `DropdownController#getMenuItems` looks them up, by `[role="menuitem"]`—, so loose
      # text is skipped and the fix was left purely visual. As a description and not as an
      # `aria-label` so as not to clobber the accessible name: the visible one is still
      # "CSV" and "Label in Name" is not broken.
      def export_menu_items
        return [] unless @export_options

        items = [ { tag: :title, name: I18n.t(EXPORT_MENU_TITLE_KEY), id: export_menu_title_id } ]
        export_component.export_items.each do |item|
          # `method: nil` so that Link does not emit Rails-UJS's `data-method="get"`, which
          # does nothing under Turbo. `data-turbo="false"` IS needed: a CSV is not a response
          # Turbo Drive can render, and the visit stalls halfway instead of firing the
          # download.
          items << { href: item[:url], name: item[:label], icon: item[:icon], method: nil,
                     "aria-describedby": export_menu_title_id,
                     data: { turbo: false, export_links_target: "link" } }
        end
        items
      end

      # Unique per render and not fixed: two page components on the same page would repeat
      # the id, and `aria-describedby` would resolve both of them to the first one.
      def export_menu_title_id
        @export_menu_title_id ||= "bali-export-menu-title-#{SecureRandom.hex(4)}"
      end

      # Re-syncing the hrefs from `window.location` is a reasonable guess ONLY when the slice
      # came from the request. With an explicit `params:` the host has already decided what
      # to export —including `{}`, the "export everything on purpose" opt-out— and the
      # controller undid that as soon as Stimulus booted, with the Ruby tests green.
      def export_links_sync?
        @export_options.nil? || @export_options[:params].nil?
      end

      # The params are resolved HERE and passed explicitly: the Export is built to read its
      # `export_items` and is never rendered, and `request_query_params` needs the render
      # context that only the component actually being painted has.
      def export_component
        @export_component ||= Bali::DataTable::Export::Component.new(
          formats: @export_options[:formats],
          url: @export_options[:url],
          params: @export_options[:params] || request_query_params
        )
      end

      def breadcrumb_spacer_class
        "mt-1" if render_breadcrumbs?
      end

      def render_breadcrumbs
        return unless render_breadcrumbs?

        render(Bali::Breadcrumb::Component.new) do |bc|
          breadcrumbs.each { |crumb| bc.with_item(**crumb) }
        end
      end

      def render_actions_bar
        return unless actions? || secondary_actions?

        helpers.tag.div(class: "flex items-center gap-2 flex-wrap max-sm:w-full") do
          helpers.safe_join([ *actions, render_secondary_actions ].compact)
        end
      end

      # Renders the optional nav slot (second-level navigation, e.g. Bali::Tabs)
      # between the PageHeader and the body with standardized spacing.
      def render_nav
        return unless nav?

        helpers.tag.div(class: "page-nav mt-4") { nav.to_s }
      end

      # The page container. `mx-auto` without a `max-w-*` centers nothing, so they go
      # together and always: `max_width: :full` is a deliberate no-op, not an absence.
      def page_container_class(*extra)
        class_names(*extra, "mx-auto", max_width)
      end

      # The header of the five. `title:` and `subtitle:` travel as constructor arguments —and
      # not through the `with_title`/`with_subtitle` slots— so that the five share
      # `PageHeader::TITLE_CLASSES` and `SUBTITLE_CLASSES`, and so that PageHeader is the one
      # emitting the `h1`: passing it as a block made the slot wrap the block in a heading
      # and the title ended up being whatever the block decided.
      #
      # `title_tags` goes to PageHeader's slot of the same name, which places them as
      # SIBLINGS of the heading. Inside the `h1` they became part of its accessible name and
      # the header was announced as "The Matrix Action Released" (#685).
      def render_page_header
        render(Bali::PageHeader::Component.new(
          title: title,
          heading: heading,
          subtitle: subtitle,
          back: back,
          class: breadcrumb_spacer_class
        )) do |header|
          title_tags.each { |title_tag| header.with_title_tag { title_tag.to_s } }
          page_header_actions
        end
      end

      # The right-hand slot of the header. DocumentPage extends it with its panel toggles;
      # the rest keep just the actions bar.
      def page_header_actions
        render_actions_bar
      end

      def render_body
        return unless page_body?

        helpers.tag.div(render_body_with_sidebar, class: BODY_SPACING_CLASS)
      end

      # ShowPage and FormPage painted the SAME grid with the same six classes; the only real
      # difference was that FormPage wraps the body in a Card. That is `page_body`, which
      # FormPage overrides, not a copy of the grid.
      def render_body_with_sidebar
        return page_body unless sidebar?

        widths = SIDEBAR_WIDTHS.fetch(sidebar_width)

        helpers.tag.div(class: "grid grid-cols-1 #{widths[:grid]} gap-4 lg:gap-6") do
          helpers.safe_join([
            helpers.tag.div(page_body, class: widths[:main]),
            helpers.tag.div(sidebar, class: "space-y-6")
          ])
        end
      end

      # `.to_s` and not the bare slot: a slot returned from a Ruby block reaches `capture` as
      # an object, and `capture` only understands String or SafeBuffer — anything else it
      # discards in silence and the block comes out empty. Same reason as the `nav.to_s` in
      # `render_nav`.
      def page_body
        body.to_s
      end

      def page_body?
        body?
      end

      attr_reader :sidebar_width

      def resolve_sidebar_width(value)
        key = (value || :default).to_sym
        return key if SIDEBAR_WIDTHS.key?(key)

        raise ArgumentError,
              "Unknown sidebar_width: #{value.inspect}. Valid: #{SIDEBAR_WIDTHS.keys.join(', ')}"
      end
    end
  end
end
