# frozen_string_literal: true

module Bali
  module BulkActions
    module Action
      class Component < ApplicationViewComponent
        attr_reader :label, :href, :method, :variant, :size, :target

        # One table for every `.btn` in the library. See Bali::ButtonTaxonomy.
        VARIANTS = Bali::ButtonTaxonomy::VARIANTS
        SIZES = Bali::ButtonTaxonomy::SIZES

        CONTROL_ON_GET_MESSAGE = "BulkActions action %p declares `with_control` but uses " \
                                 "`method: :get`, which renders a link instead of a form: a " \
                                 "link has no form to carry the control's value, so it would " \
                                 "be submitted nowhere. Use the default `method: :post` (or " \
                                 "any other non-GET verb) for actions that take an input."

        # A host control that travels with THIS action: a driver select, a date field,
        # whatever. It renders INSIDE the action's `form_with` and before the submit, so its
        # value travels with the POST without a line of JS.
        #
        # WATCH the ids: the block is host markup, and two actions mounting the same control
        # repeat its id in the document (the first one takes the `label for=`). If two
        # actions share a control, give each one its own `id:` — or `id: nil` if there is no
        # label to point at. Same gotcha `preserved_params_hidden_fields` solved with
        # `id: nil` in Filters.
        renders_one :control

        # @param label [String] Button/link text.
        # @param href [String] Destination of the action.
        # @param method [Symbol] HTTP verb. `:get` renders a link; any other one, a form of
        #   its own with the hidden field of selected ids.
        # @param size [Symbol] Button size. The bar injects it according to its variant
        #   (`xs` in the contextual row, `sm` in the floating one); passing it explicitly wins.
        # @param select_all_filtered [Boolean] Injected by the bar: when the "the N filtered"
        #   mode is available, the action emits the `select_all_filtered` hidden field that
        #   the JS flips, and re-emits the filters in force. Without it the POST goes out
        #   just as it always did.
        # @param filter_params [Array<Array>] `[name, value]` pairs of the listing's current
        #   `q[...]`. They travel WHENEVER the mode is available, active or not: the flag is
        #   what tells the server whether to look at them or stay with the ids.
        # @param target [String, Symbol] Context the action opens in (`"_blank"` to print in
        #   a new tab). On a form action it goes to the `<form target>`; on a GET action, to
        #   the `<a target>`. It is a first-class option because `form_with` only honors a
        #   handful of loose options (`id`, `class`, `data`, ...) and was swallowing a
        #   `target:` passed through **options without saying anything.
        # rubocop:disable Metrics/ParameterLists
        def initialize(label:, href:, method: :post, variant: :secondary, size: :sm,
                       target: nil, select_all_filtered: false, filter_params: [], **options)
          # rubocop:enable Metrics/ParameterLists
          @label = label
          @href = href
          @select_all_filtered = select_all_filtered
          # Normalized here too: an action mounted by hand (outside the bar) can receive a
          # nested hash, and `Array(hash)` left it as a single `q` hidden field with the
          # hash's `to_s` inside — a well-formed POST that filters nothing.
          @filter_params = select_all_filtered ? Bali::Filters::ActiveFilterParams.normalize(filter_params) : []
          @method = method.to_sym
          @variant = variant.to_sym
          @size = size.to_sym
          @target = target.presence
          @variant_class = Bali::ButtonTaxonomy.variant!(self.class, @variant)
          @size_class = Bali::ButtonTaxonomy.size!(self.class, @size)
          @options = options
        end

        def call
          # `with_control` is declared INSIDE the action's content block, and a slot
          # declared there does not exist until the block runs. Without forcing it,
          # `control?` is always `false` and the control disappeared silently. `content` is
          # memoized, so this evaluates it ONCE.
          content

          validate_control_method!

          if get_request?
            render_link_action
          else
            render_form_action
          end
        end

        private

        # Fail-fast, the repo's pattern (mirrors `resolve_simple_input` in Bali::FilterForm):
        # a GET action with a control renders a link that ignores the input, and the user
        # picks a value that never reaches the server. Silent and very expensive to diagnose.
        def validate_control_method!
          return unless get_request? && control?

          raise ArgumentError, format(CONTROL_ON_GET_MESSAGE, label)
        end

        def get_request?
          method == :get
        end

        def render_link_action
          render Bali::Link::Component.new(
            name: label,
            href: link_href,
            variant: variant,
            size: size,
            data: { bulk_actions_target: "bulkAction" },
            **link_options
          )
        end

        # Explicit `builder:`: an action's form cannot change shape just because the host
        # declares `default_form_builder = Bali::FormBuilder` (what
        # docs/guides/installation.md recommends and what the group's six apps have on).
        # With Bali's builder, `form.submit` came out as `<button class="btn btn-primary">`:
        # the POST's `name="commit"` was lost and the builder's `btn-primary` sat glued in
        # front of the real variant (`btn btn-primary btn btn-sm btn-error`, which one paints
        # decided by stylesheet order and not by the action) (#1137). The `data-disable-with`
        # comes back with the `<input>`, but it does not count as an argument: rails-ujs
        # reads it and none of the six apps has it. It goes before the splat on purpose: a
        # `builder:` the host passes to `with_action` still wins, and a test covers that.
        # Moving this form to the Bali builder's idiom is another discussion, set aside for
        # v4 (#903).
        def render_form_action
          helpers.form_with(url: href, method: method, class: "contents",
                            builder: ActionView::Helpers::FormBuilder, **form_options) do |form|
            safe_join(
              [
                # `id: nil` because each action is its own form and all of them emit THIS
                # field: with the id derived from the name, a bar of three actions repeated
                # `id="selected_ids"` three times in the document. The JS looks it up by its
                # Stimulus target, not by id. Same fix as `preserved_params_hidden_fields`.
                form.hidden_field(:selected_ids, value: [], id: nil, data: bulk_action_data),
                select_all_filtered_field,
                filter_params_fields,
                control,
                form.submit(label, class: button_classes)
              ].compact
            )
          end
        end

        # The flag starts at "false" and the JS flips it when the mode is entered. It is
        # always emitted (not `disabled` when off) so the POST has ONE single shape: the
        # server reads the flag, not the absence of a field.
        def select_all_filtered_field
          return unless @select_all_filtered

          helpers.hidden_field_tag(
            "select_all_filtered", "false",
            id: nil, data: { bulk_actions_target: "selectAllFilteredField" }
          )
        end

        # `id: nil` because these same fields are painted in EVERY form of the bar.
        def filter_params_fields
          return if @filter_params.blank?

          safe_join(
            @filter_params.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) }
          )
        end

        # A GET action has no hidden fields to put the filters in, so they travel in its
        # href. Any `q[...]` the href already carried is dropped first: the listing's current
        # state is what rules, and two sets of `q` in the same URL clobber each other in ways
        # that depend on the parser.
        def link_href
          return href if @filter_params.blank?

          uri = URI.parse(href.to_s)
          kept = Rack::Utils.parse_query(uri.query)
                            .reject { |name, _| name == "q" || name.start_with?("q[") }
                            .flat_map { |name, value| Array(value).map { |v| [ name, v ] } }
          uri.query = Rack::Utils.build_query(kept + @filter_params.map { |n, v| [ n.to_s, v.to_s ] })
          uri.to_s
        end

        # `form_with` honors `html:` for whatever is not in its short list of loose options,
        # and that is where `target` has to go.
        def form_options
          return @options if target.blank?

          @options.merge(html: (@options[:html] || {}).merge(target: target))
        end

        # `Link` splats its **options as attributes of the `<a>`, so `target` gets there on
        # its own.
        def link_options
          return @options if target.blank?

          @options.merge(target: target)
        end

        def bulk_action_data
          { bulk_actions_target: "bulkAction" }
        end

        # `"btn-#{size}"` was invisible to Tailwind's scanner: the class only ever shipped
        # because some other component happened to spell it out.
        def button_classes
          class_names("btn", @size_class, @variant_class)
        end
      end
    end
  end
end
