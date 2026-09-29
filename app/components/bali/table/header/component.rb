# frozen_string_literal: true

module Bali
  module Table
    module Header
      class Component < ApplicationViewComponent
        attr_reader :hidden

        SORT_ICONS = { "asc" => "chevron-up", "desc" => "chevron-down" }.freeze
        UNSORTED_ICON = "chevrons-up-down"
        ARIA_SORT = { "asc" => "ascending", "desc" => "descending" }.freeze

        def initialize(name: nil, form: nil, sort: nil, hidden: false, **options)
          @name = name
          @form = form
          @sort_attribute = sort
          @hidden = hidden
          @options = prepend_class_name(hyphenize_keys(options), "whitespace-nowrap")
        end

        def call
          if @sort_attribute.present? && @form.blank?
            # QUALIFIED on purpose: `MissingFilterForm` lives in `Bali::Table::Component`, which
            # is NOT a lexical parent of this class (`Header::Component` → `Header` → `Table` →
            # `Bali`). Unqualified, this raise blew up with a NameError instead of the
            # documented error — never noticed, because no test exercised the guard until now.
            raise Bali::Table::Component::MissingFilterForm, "FilterForm is required for sorting"
          end

          if sortable?
            opened = helpers.params.delete("opened")
            @name = sort_link
            helpers.params["opened"] = opened
          end

          tag.th(@name, **th_options)
        end

        private

        def sortable?
          @sort_attribute.present? && @form.present?
        end

        # Ransack only paints an arrow on the SORTED column (`default_arrow` is nil), so a
        # sortable column looked identical to one that is not: there was no way to know it
        # could be clicked other than by clicking it. Its indicator is turned off and the
        # label is built by the component. WATCH OUT: `sort_link` merges into the HREF every
        # option that is not class/data — a `title:` here ends up as `&title=...` in the URL.
        def sort_link
          helpers.sort_link(
            @form.ransack_search, @sort_attribute, sort_link_label,
            hide_indicator: true,
            class: "group inline-flex items-center gap-1"
          )
        end

        def sort_link_label
          safe_join([ @name, sort_indicator ].compact)
        end

        # `aria-hidden` because `aria-sort` on the th already announces the state; Ransack's
        # text arrow (&#9660;) was read out on top of that as "black down-pointing triangle".
        def sort_indicator
          render Bali::Icon::Component.new(
            SORT_ICONS.fetch(sort_direction, UNSORTED_ICON),
            class: indicator_classes, "aria-hidden": true
          )
        end

        # Dimmed until the pointer (or keyboard focus) arrives: the affordance has to tell a
        # sortable column apart without competing with the table's data.
        #
        # Explicit colour and NOT `opacity`: daisyUI already paints the thead with
        # `base-content` at 60%, so an opacity MULTIPLIES against that — `opacity-30` measured
        # 1.5:1 against base-100, below the 3:1 WCAG 1.4.11 asks of a user interface element.
        # And since the only highlight is hover/focus, on a phone there is no way to raise it:
        # the affordance stayed down there forever, for exactly the people who see it least.
        def indicator_classes
          return "shrink-0 opacity-100" if sort_direction

          "shrink-0 text-base-content/60 transition-colors " \
            "group-hover:text-base-content group-focus-visible:text-base-content"
        end

        def sort_direction
          return @sort_direction if defined?(@sort_direction)

          @sort_direction = @form.ransack_search.sorts
                                 .find { |sort| sort && sort.name == @sort_attribute.to_s }&.dir
        end

        # `aria-sort` is the only thing that tells a screen reader that the column is
        # sortable and which way it is sorted: the new affordance is purely visual.
        def th_options
          return @options unless sortable?

          @options.merge("aria-sort": ARIA_SORT.fetch(sort_direction, "none"))
        end
      end
    end
  end
end
