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

      # THE BUILDER CONTRACT, relied on by every `list`/`row`/`series`/`trend`/
      # `goal` declaration and restated by none of them:
      #
      #   1. A builder is `dup`ed before it is written to. `class_attribute`
      #      copies on WRITE and never on MUTATION, so without the dup two
      #      siblings overwrite each other's fields — last class body loaded
      #      winning, presenting as "widget B shows widget A's title" and varying
      #      with autoload order.
      #
      #   2. That `dup` is SHALLOW, which suffices only because every setter
      #      ASSIGNS rather than mutates and no builder exposes a reader. Add an
      #      accumulating field or a reader that hands out the ivar and parent and
      #      child start sharing one object through the copy.
      #
      # `test/bali/widget/patterns_test.rb` pins (1) for all four builders.

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

      # Copy is HOST content. It reads from i18n by default — `widgets.<key>.*` —
      # and a class may set a literal instead, which is what a widget with one
      # hardcoded string wants rather than four locale keys.
      class_attribute :_title, **ATTRIBUTE_OPTIONS
      class_attribute :_short_title, **ATTRIBUTE_OPTIONS
      class_attribute :_description, **ATTRIBUTE_OPTIONS
      class_attribute :_empty_message, **ATTRIBUTE_OPTIONS

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
        # Deliberately does NOT check `_supported_sizes`: `ValueBase` ships with
        # `[:small]`, so a widget widening it writes `default_size :medium` above
        # `supports :small, :medium` and the check would reject a legitimate
        # class. `supports` validates the pair instead, which makes the two
        # ORDER-DEPENDENT — `supports` must come second.
        def default_size(name = nil)
          return _default_size if name.nil?

          raise ArgumentError, "unknown widget size #{name.inspect}" unless SIZES.include?(name)

          self._default_size = name
        end

        def supports(*names)
          unknown = names - SIZES
          raise ArgumentError, "unknown widget size(s) #{unknown.inspect}" if unknown.any?
          raise ArgumentError, "a widget must support at least one size" if names.empty?
          unless names.include?(_default_size)
            raise ArgumentError,
                  "#{name_for_error} defaults to #{_default_size.inspect} but only offers " \
                  "#{names.inspect} — the default must be one a user can choose."
          end

          self._supported_sizes = names
        end

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

        private

        def translate(suffix, **options)
          I18n.t("#{i18n_scope}.#{key}.#{suffix}", **options)
        end

        def name_for_error = name || "This widget"
      end

      attr_reader :context

      # `context` is whatever the host needs to gate and scope on — a Pundit
      # context, a user, a tenant, nothing at all. Bali never reads it.
      def initialize(context = nil)
        @context = context
      end

      delegate :key, :title, :short_title, :description, :empty_message,
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

      # Where the tile links. On `Base` because a figure, a trend and a ring all
      # link somewhere just as a list does.
      def view_all_path = _view_all_path && instance_exec(&_view_all_path)
    end
  end
end
