# frozen_string_literal: true

module Bali
  module Widget
    # What every widget has, regardless of which ladder it walks. The data half
    # lives on the pattern subclasses.
    #
    # A WIDGET RAISES. It does not rescue itself, does not report, and has no
    # `failed?` — `Bali::Widget::Component` is an ERROR BOUNDARY around one tile,
    # and that is where a failure is caught, reported and degraded. "One tile
    # must not take the page down" is a fact about the page, and a widget knows
    # nothing about being one of twelve.
    #
    # THE PATTERN IS THE TYPE. A widget picks exactly one of `ValueBase`,
    # `ListBase`, `TrendBase`, `ProgressBase` or `CheckBase`, and that is not a
    # claim it can contradict — it is what gives the class its declarations.
    # Choosing `TrendBase` and not declaring `t.current` is a loud failure, not a
    # card that renders half a thing.
    class Base
      # Class-level configuration. The instance writer `class_attribute` generates
      # by default would silently shadow the class value for one object. Instance
      # READERS stay: the patterns read them.
      ATTRIBUTE_OPTIONS = { instance_writer: false, instance_predicate: false }.freeze

      # The canvas the widget is drawn around, and the fallback for a stored size
      # it no longer supports.
      class_attribute :_default_size, default: SIZES.first, **ATTRIBUTE_OPTIONS

      # Which sizes a USER may choose. Declare a subset when the widget has
      # nothing to fill the others with.
      #
      # DECLARED rather than inferred from the data: inferring would mean loading
      # every widget just to render a picker, and would make the offered sizes
      # vary week to week as data comes and goes.
      class_attribute :_supported_sizes, default: SIZES, **ATTRIBUTE_OPTIONS

      # The shortest interval `refresh_every` accepts. Not a guess about what is
      # useful — a floor under what is affordable.
      MINIMUM_REFRESH = 5

      # Copy is HOST content. It reads from i18n by default — `widgets.<key>.*` —
      # and a class may set a literal instead, which is what a widget with one
      # hardcoded string wants rather than four locale keys.
      class_attribute :_title, **ATTRIBUTE_OPTIONS
      class_attribute :_short_title, **ATTRIBUTE_OPTIONS
      class_attribute :_description, **ATTRIBUTE_OPTIONS
      class_attribute :_empty_message, **ATTRIBUTE_OPTIONS
      # How often the card re-fetches itself, or nil for never. A property of the
      # DATA — how fast it goes stale — so it belongs to the widget rather than
      # to the arrangement or the page.
      class_attribute :_refresh_every, **ATTRIBUTE_OPTIONS

      # Bali's own chrome lives under `bali_view.widgets.*`; this is the scope a
      # host's titles live in.
      class_attribute :i18n_scope, default: "widgets", **ATTRIBUTE_OPTIONS

      # Where the tile links. A block, because it is a route helper rather than a
      # value — and on `Base` rather than `ListBase` because a figure, a trend and
      # a ring all link somewhere just as a list does.
      class_attribute :_view_all_path, **ATTRIBUTE_OPTIONS

      # The persisted identity. Derived unless a class says otherwise — see `.key`.
      class_attribute :_key, **ATTRIBUTE_OPTIONS

      class << self
        def default_size(name = nil)
          return validated_default_size if name.nil?

          raise ArgumentError, "unknown widget size #{name.inspect}" unless SIZES.include?(name)

          self._default_size = name
        end

        # `default:` so widening a restricted pattern is ONE line:
        #
        #   supports :small, :medium, default: :medium
        #
        # The pair is validated on READ, not here — the two macros must work in
        # either order. See `docs/reference/widget-design-notes.md`.
        def supports(*names, default: nil)
          unknown = names - SIZES
          raise ArgumentError, "unknown widget size(s) #{unknown.inspect}" if unknown.any?
          raise ArgumentError, "a widget must support at least one size" if names.empty?

          self._supported_sizes = names
          default_size(default) if default
        end

        # DEFINES A DECLARATION MACRO — `row`, `trend`, `goal`, `check`, `series`.
        #
        # The `dup` is the part that matters: `class_attribute` copies on WRITE
        # and never on MUTATION, so without it two siblings overwrite each other's
        # fields, last class body loaded winning. It is SHALLOW, which suffices
        # only because every builder setter assigns rather than mutates and none
        # exposes a reader — see `patterns_test.rb`.
        #
        # `build` is a block so a pattern can seed its builder from class state.
        def declares(name, hint:, &build)
          attribute = :"_#{name}_builder"
          class_attribute attribute, **ATTRIBUTE_OPTIONS

          define_singleton_method(name) do |&block|
            raise ArgumentError, "`#{name}` needs a block: `#{hint}`." unless block

            builder = public_send(attribute)&.dup || instance_exec(&build)
            public_send(:"#{attribute}=", builder)
            block.call(builder)
          end
        end
        # Plumbing, not part of the DSL a host writes. Receiverless calls from a
        # class body still reach it, which is the only way it is ever used.
        private :declares

        def view_all_path(&block) = self._view_all_path = block

        def supported_sizes = _supported_sizes

        # THE PERSISTED IDENTITY, and the i18n scope. `Widgets::LowStockItems` ->
        # `"low_stock_items"`.
        #
        # DEMODULIZED ON PURPOSE, so not unique by construction:
        # `Reports::Overdue` and `Tasks::Overdue` collide. `Bali::Widget.by_key`
        # raises rather than letting one win, and the fix is `key "reports_overdue"`.
        #
        # NOT namespace-qualified, which would make keys unique for free: a
        # qualified key is `constantize`-able, and the security property is that a
        # submitted key becomes a widget only by being FOUND in the offering. A
        # stored qualified key would also break every dashboard the day a class
        # moved namespace.
        def key(value = nil)
          return self._key = value.to_s if value

          _key || @key ||= name.demodulize.underscore
        end

        # Read with no argument, set with one. A widget with a single literal
        # string says `title "Overdue tasks"`; one with translations says nothing
        # and gets `widgets.<key>.title`.
        def title(value = nil) = value.nil? ? (_title || translate(:title)) : (self._title = value)

        # The `small` card is ~215px wide, where a long title wraps to three
        # lines. Falls back to the full title, so a widget only needs a short one
        # if its real one does not fit.
        def short_title(value = nil)
          return self._short_title = value unless value.nil?

          _short_title || translate(:short_title, default: title)
        end

        # One line telling a picker what this widget shows. Several titles are
        # usually near-neighbours, so the label alone does not distinguish them.
        def description(value = nil)
          value.nil? ? (_description || translate(:description)) : (self._description = value)
        end

        # Shown by the card's list body when there is nothing to list.
        def empty_message(value = nil)
          value.nil? ? (_empty_message || translate(:empty)) : (self._empty_message = value)
        end

        # OPT-IN, and off by default: most widgets answer a question that does
        # not change between page loads, and polling them costs a query per tile
        # per interval for nothing.
        #
        #   refresh_every 30.seconds
        #
        # Read with no argument, like every other declaration here — without the
        # guard, `refresh_every` in a reader position would silently switch
        # refreshing off.
        #
        # FLOORED, because the cost is paid by the server and a plausible typo
        # (`0.5` for `5`) turns one tile into a load generator. Validated at
        # class-definition time, so it is a boot failure rather than a surprise
        # in production.
        def refresh_every(value = nil)
          return _refresh_every if value.nil?

          seconds = value.to_f
          if seconds < MINIMUM_REFRESH
            raise ArgumentError,
                  "#{name_for_error} asks to refresh every #{seconds}s; the minimum is " \
                  "#{MINIMUM_REFRESH}s. Each refresh is a request and a query per tile."
          end

          self._refresh_every = seconds
        end

        private

        def translate(suffix, **options)
          I18n.t("#{i18n_scope}.#{key}.#{suffix}", **options)
        end

        def name_for_error = name || "This widget"

        # CHECKED ON READ, so the two macros can appear in either order. A class
        # that never renders never asks — which is why `dashboard_widgets` runs
        # `Bali::Widget.check_catalog!` and turns this back into a boot failure
        # for every widget a host actually put on a dashboard.
        def validated_default_size
          return _default_size if _supported_sizes.include?(_default_size)

          raise ArgumentError,
                "#{name_for_error} defaults to #{_default_size.inspect} but only offers " \
                "#{_supported_sizes.inspect} — the default must be one a user can choose."
        end
      end

      attr_reader :context

      # `context` is whatever the host needs to gate and scope on — a Pundit
      # context, a user, a tenant, nothing at all. Bali never reads it.
      def initialize(context = nil)
        @context = context
      end

      delegate :key, :title, :short_title, :description, :empty_message, :refresh_every,
               :supported_sizes, to: :class

      # MAY THIS OWNER SEE THIS WIDGET? Overridden by the host — Bali owns the
      # hook and never the rule.
      #
      #   def authorized? = context.has_any_role?(:finance)
      #
      # NOT `visible?`: this governs whether the widget may be persisted, offered
      # and rendered AT ALL, not whether it should be on screen right now. Named
      # `visible?`, a host could reasonably write a presentation condition into it
      # and be surprised that it also governs what the database accepts.
      #
      # It may QUERY, but must not run the widget's own DATA queries — that split
      # is what lets a picker list thirty widgets without loading thirty. Not
      # memoised for you: the default is a constant, and a host whose rule is
      # expensive knows that where Bali cannot.
      def authorized? = true

      def view_all_path = _view_all_path && instance_exec(&_view_all_path)

      # ---- what a PATTERN answers ----------------------------------------------
      #
      # DECLARED HERE, IMPLEMENTED NOWHERE. The card asks every widget these three
      # and cannot ask what kind it is holding, so the contract has to be stated
      # once — but `Base` cannot answer them, because each means something
      # different per pattern: `count` is rows for a list and a dollar sum for a
      # figure. The same shape `Card::Component` uses for `headline`.
      #
      # A widget subclassing `Base` directly is not a supported thing: THE PATTERN
      # IS THE TYPE, and these say so by name rather than through the
      # `NoMethodError` a bare subclass used to raise from inside the card.

      # HOW MANY, OR HOW MUCH — whatever this widget's headline counts.
      def count = pattern_required(:count)

      # HAS THIS WIDGET ANYTHING TO SAY? Drives the card's dimming, its empty
      # state and its "view all" link. NOT `count.positive?`: `count` is a figure
      # for some patterns, so a legitimate negative would read as "nothing here".
      def any? = pattern_required(:any?)

      # WHAT THE HEADLINE PRINTS.
      def display_value = pattern_required(:display_value)

      private

      # FULLY QUALIFIED, because a host reads this message and then types what it
      # says — and `class Foo < ValueBase` is a `NameError`.
      def pattern_required(contract)
        patterns = %w[ValueBase ListBase TrendBase ProgressBase CheckBase]
                   .map { |pattern| "Bali::Widget::#{pattern}" }

        raise NotImplementedError,
              "#{self.class.name || 'This widget'} must subclass one of " \
              "#{patterns.join(', ')} — `#{contract}` comes from the pattern."
      end
    end
  end
end
