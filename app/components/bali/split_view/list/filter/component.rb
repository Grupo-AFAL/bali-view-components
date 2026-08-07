# frozen_string_literal: true

module Bali
  module SplitView
    module List
      module Filter
        # One filter pill in a SplitView listing's filter band.
        #
        # It is a **link**, not a form control. Clicking it is an ordinary GET to a
        # URL, which is what makes the rest of the listing behave without a line of
        # code: the server renders page one, so the infinite scroll resets, and the
        # filter params ride along into every page the sentinel fetches afterwards.
        # That is also why there is no submit button, no clear button and no form
        # around the band.
        #
        # **The component builds the URL.** Declare what the pill filters by and it
        # works out the rest from the current request:
        #
        #   <% list.with_filter(label: "Aprobaciones", param: :bucket,
        #                       value: "aprobaciones", count: 12) %>
        #
        # What "clicking it" means depends on the list's `filter_mode:`:
        #
        # - `:single` (default) — one value at a time, the shape of a bucket strip.
        #   Clicking an inactive pill replaces whatever was there; clicking the
        #   active one drops the param, which is what replaces a Clear button.
        # - `:multi` — each pill toggles independently over a multi-valued param
        #   (`q[status_in][]`). Clicking one adds or removes **its** value and
        #   leaves the other values alone.
        #
        # Every other param in the request survives the trip — except `page`, which
        # is dropped on purpose: filtering starts the listing over, and carrying
        # page 4 into a filter that has two pages of results is a blank screen.
        #
        # `href:` is the escape hatch for a URL this cannot express, and `active:`
        # for a "current" this cannot infer. Passing `href:` without `param:` is the
        # whole of the old API and still works.
        #
        # ## Why the active pill is not `aria-pressed`
        #
        # A toggle that is a link cannot say so in ARIA. Browsers drop
        # `aria-pressed` on `role=link` — the reason `Bali::ViewSwitch` stopped
        # emitting it (see `view_switch/view/component.rb`, and the v2→v3 migration
        # guide) — so an attribute there would announce nothing at all.
        #
        # What each mode does instead:
        #
        # - `:single` marks the active pill `aria-current="true"`. That is the
        #   doctrine's atom: a global attribute, valid on any role, meaning "the
        #   current item of this set". There is exactly one, which is what
        #   `aria-current` is for.
        # - `:multi` does **not** use it. Several pills are active at once, and
        #   `aria-current` on all of them says "these are all the current one",
        #   which is not a sentence. The state lives in text instead.
        #
        # In both modes the active pill carries an `sr-only` note saying it is on
        # and that clicking removes it. That is the part a sighted reader gets from
        # the colour and everyone else got nothing from — and it doubles as the
        # link's purpose, which is what a screen reader most needs from a link whose
        # visible text is one word.
        #
        # The styling hangs off `data-active`, not off either ARIA attribute, so the
        # look does not change with the mode and the semantics are free to.
        class Component < ApplicationViewComponent
          BASE_CLASSES = "split-view-filter"
          COUNT_CLASSES = "split-view-filter-count"

          MODES = %i[single multi].freeze

          # Paging and filtering do not compose: page 4 of an unfiltered list is
          # nowhere in a filtered one.
          RESET_PARAMS = %w[page].freeze

          attr_reader :label, :count

          def initialize(label:, param: nil, value: nil, href: nil, active: nil,
                         count: nil, mode: :single, **options)
            @label = label
            @param = param
            @value = value
            @href = href
            @active = active
            @count = count
            @mode = MODES.include?(mode&.to_sym) ? mode.to_sym : :single
            @options = options

            return if @href || @param

            raise ArgumentError,
                  "with_filter needs either `param:` (and `value:`) so the pill can build its " \
                  "own URL, or an explicit `href:`."
          end

          def multi? = @mode == :multi

          def active?
            return !!@active unless @active.nil?
            return false if @param.nil?

            multi? ? current_values.include?(value) : current_values.first == value
          end

          # Explicit `href:` wins; otherwise the toggle URL for this pill.
          def href
            @href || toggle_href
          end

          private

          attr_reader :options

          def value = @value.to_s

          # "q[status_in]" -> ["q", "status_in"]. A bare `:status` is a one-step path.
          def param_path
            @param_path ||= @param.to_s.scan(/[^\[\]]+/)
          end

          def query_params
            @query_params ||= request.query_parameters.deep_dup.except(*RESET_PARAMS)
          end

          def current_values
            Array(dig_param(query_params)).map(&:to_s)
          end

          def dig_param(params)
            param_path.reduce(params) { |scope, key| scope.is_a?(Hash) ? scope[key] : nil }
          end

          def toggle_href
            # `deep_dup` and not the memo itself: `write_param` mutates, and
            # `link_to(href, **link_attributes)` evaluates `href` first — so
            # writing through the memo left `active?` reading the state AFTER the
            # toggle it was about to produce, and every pill rendered inverted.
            params = query_params.deep_dup
            write_param(params, next_values)

            query = Rack::Utils.build_nested_query(params)
            query.present? ? "#{request.path}?#{query}" : request.path
          end

          # What the param should hold once this pill has been clicked. `nil` means
          # "drop it" — a single-mode pill turning itself off, or the last value
          # leaving a multi-mode array.
          def next_values
            return multi? ? (current_values - [ value ]).presence : nil if active?
            return current_values | [ value ] if multi?

            value
          end

          def write_param(params, values)
            *ancestors, key = param_path
            scope = ancestors.reduce(params) { |acc, name| descend(acc, name) }

            values.nil? ? scope.delete(key) : scope[key] = values
            prune_empty(params, ancestors)
          end

          # `acc[name] ||= {}` is not enough here, and the reason is worth the
          # method: `request.query_parameters` is a HashWithIndifferentAccess,
          # which CONVERTS a plain Hash on write. The assignment then evaluates to
          # the right-hand side — the original `{}` — while what got stored is a
          # converted copy, so writing through the returned object updated a hash
          # nobody would ever read. Reading the key back returns the stored one.
          def descend(scope, key)
            scope[key] ||= {}
            scope[key]
          end

          # Dropping the last value of `q[status_in]` must not leave `?q=` behind.
          def prune_empty(params, ancestors)
            ancestors.each_index.reverse_each do |index|
              path = ancestors[0..index]
              *parents, key = path
              scope = parents.reduce(params) { |acc, name| acc[name] }
              scope.delete(key) if scope[key].is_a?(Hash) && scope[key].empty?
            end
          end

          def link_attributes
            options.except(:class, :aria, :data).merge(
              class: class_names(BASE_CLASSES, options[:class]),
              data: (options[:data] || {}).merge(active: active?.to_s),
              aria: (options[:aria] || {}).merge(
                current: (active? && !multi? ? "true" : nil)
              )
            )
          end
        end
      end
    end
  end
end
