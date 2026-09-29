# frozen_string_literal: true

module Bali
  module BulkActions
    class Component < ApplicationViewComponent
      # Button size is decided by the BAR, not by whoever declares the action: in the
      # contextual row the buttons sit INSIDE a tinted surface of fixed height, so an `sm`
      # (32px, exactly the height of the bar) ends up flush with the edges and looks cramped.
      # `xs` (24px) leaves 4px of air above and below without touching the total height
      # —which has to stay the one of the toolbar it replaces—. The floating bar has no such
      # limit and keeps `sm`. An explicit `size:` on the action beats both.
      #
      # `select_all_filtered:` and `filter_params:` go AFTER the splat: they belong to the
      # component, not to whoever declares the action — the bar is the only one that knows
      # whether the "the N filtered" mode is available, and the actions have to agree with
      # each other.
      renders_many :actions, ->(**options) do
        Action::Component.new(
          size: toolbar? ? :xs : :sm,
          **options,
          select_all_filtered: select_all_filtered?,
          filter_params: filter_params
        )
      end
      renders_many :items, Item::Component

      VARIANTS = %i[floating toolbar].freeze

      # Height of a daisyUI `sm` control (btn-sm / input-sm), which is what gives the
      # DataTable toolbar its height. The contextual row REPLACES it in the same slot, so both
      # declare this same minimum: if they differ, swapping them shifts the listing.
      # `Bali::DataTable::Component::TOOLBAR_CLASSES` declares the twin, and a test pins it.
      TOOLBAR_MIN_HEIGHT = "min-h-8"

      # Two sets of classes: the floating bar (outside a listing) and the contextual row that
      # takes the slot of a DataTable's toolbar while there is a selection.
      CLASSES = {
        floating_bar: "fixed bottom-4 left-1/2 -translate-x-1/2 z-40 hidden",
        floating_bar_inner: "flex items-center shadow-xl rounded-lg overflow-hidden",
        counter: "bg-primary text-primary-content font-bold text-2xl px-4 py-2 rounded-l-lg",
        actions_wrapper: "flex gap-2 px-3 py-2 bg-base-100 rounded-r-lg",
        toolbar_bar: "hidden mb-4",
        # The primary tint is the SAME one that marks selected rows, and it works over any
        # background: `bg-base-200` was invisible in a shell whose page background already is
        # base-200 (verified in the dummy), and the bar was left with no visible state.
        #
        # HEIGHT: this row REPLACES the DataTable's toolbar, so it has to measure exactly the
        # same or swapping them shifts the listing (18px of jump measured: `py-2` contributed
        # 16 and the `border` 2). That is why the outline is a `ring` —box-shadow, zero
        # contribution to layout— instead of a `border`, and there is no vertical padding:
        # the height is fixed by `min-h-8`, the same `TOOLBAR_MIN_HEIGHT` the toolbar
        # declares, which is the height of a daisyUI `sm` control (btn-sm / input-sm). If one
        # changes, so does the other.
        toolbar_bar_inner: "flex items-center gap-2 sm:gap-4 #{TOOLBAR_MIN_HEIGHT} rounded-box " \
                           "bg-primary/10 ring-1 ring-primary/20 px-3",
        toolbar_counter_wrapper: "flex items-center gap-1 text-sm shrink-0",
        toolbar_counter: "font-semibold",
        toolbar_actions_wrapper: "flex flex-wrap items-center gap-2 flex-1",
        # The offer and the notice live INSIDE the actions container, not loose in the bar:
        # in the floating variant that container is the only one with a background
        # (`bg-base-100`), and outside it the text sat on the page background.
        select_all_offer: "hidden shrink-0",
        select_all_notice: "hidden shrink-0 text-sm italic opacity-70"
      }.freeze

      # @param variant [Symbol] :floating (bar pinned to the bottom) or :toolbar (contextual row)
      # @param standalone [Boolean] Emit the `data-controller`. Inside a DataTable it goes
      #   `false`: the controller lives on the DataTable's container. Two nested
      #   `bulk-actions` controllers split the targets between them (Stimulus assigns every
      #   target to its closest controller ancestor), so the bar would not see the rows and
      #   the counter would sit at 0 — no error, in silence.
      # @param total_count [Integer, nil] How many records the COMPLETE filtered result has,
      #   not the page. With it the bar offers "Select all N results" once the selection
      #   already covers the whole page; without it there is no offer and the selection stays
      #   strictly the visible page. The DataTable takes it from its `pagy`.
      # @param filter_params [Array<Array>, Hash] The listing's current `q[...]`, which every
      #   action re-emits as hidden fields so the server can re-derive the same scope
      #   (`MyFilterForm.new(scope, params).result`, the same code as the index). Accepts
      #   already-serialized `[name, value]` pairs or a nested hash (`{ q: { ... } }`).
      #   The DataTable builds it on its own from its `filter_form`.
      def initialize(variant: :floating, standalone: true, total_count: nil, filter_params: [],
                     **options)
        @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :floating
        @standalone = standalone
        @total_count = total_count&.to_i
        @filter_params = Bali::Filters::ActiveFilterParams.normalize(filter_params)
        @options = options
      end

      attr_reader :total_count, :filter_params

      # The offer needs an N to name. Without `total_count` there is no "all filtered" mode
      # anywhere: no offer, no hidden `select_all_filtered`, no filter re-emission — the POST
      # of a bar that does not ask for it goes out byte for byte as it did before.
      def select_all_filtered?
        @total_count.to_i.positive?
      end

      def toolbar?
        @variant == :toolbar
      end

      def standalone?
        @standalone
      end

      private

      def bar_classes
        CLASSES[toolbar? ? :toolbar_bar : :floating_bar]
      end

      def bar_inner_classes
        CLASSES[toolbar? ? :toolbar_bar_inner : :floating_bar_inner]
      end

      def actions_wrapper_classes
        CLASSES[toolbar? ? :toolbar_actions_wrapper : :actions_wrapper]
      end

      def component_classes
        class_names("bulk-actions-component", @options[:class])
      end

      def component_attributes
        data = @options[:data] || {}
        data = merge_data_attributes(data, controller: "bulk-actions") if standalone?

        @options.except(:class, :data).merge(class: component_classes, data: data)
      end

      def merge_data_attributes(existing, **new_attrs)
        (existing || {}).merge(new_attrs)
      end
    end
  end
end
