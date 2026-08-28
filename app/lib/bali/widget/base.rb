# frozen_string_literal: true

module Bali
  module Widget
    # What every widget is, regardless of which ladder it walks.
    #
    # A widget is no longer a thing that BUILDS a result; it is a thing the card
    # ASKS. `Base` answers every question the card has with a null — no rows, no
    # trend, no series, no goal — and each pattern subclass overrides the ones it
    # actually has. So the card talks to one uniform interface and never branches
    # on which kind of widget it is holding.
    #
    # THE PATTERN IS THE TYPE. A widget picks exactly one of `ValueBase`,
    # `ListBase`, `TrendBase` or `ProgressBase`, and that choice is not a claim it
    # can contradict — it is what gives the class its declarations and its
    # abstract methods. Choosing `TrendBase` and not implementing `current` is a
    # loud failure, not a card that renders half a thing.
    class Base
      # How many preview rows a list widget loads, regardless of the size it is
      # rendered at. `count` comes from the full scope, so the preview is
      # presentation rather than data — which is what keeps a widget from needing
      # to know a size. `Widget::Component` truncates to what the size has room for.
      PREVIEW_ROWS = 8

      # Every declaration below is CLASS-level configuration. The instance writer
      # `class_attribute` generates by default silently shadows the class value
      # for one object — the same trap `#with_size` dups to avoid, reachable
      # through another door — and the predicate is noise on forty-eight methods
      # nothing calls. Instance READERS stay: the patterns read them.
      ATTRIBUTE_OPTIONS = { instance_writer: false, instance_predicate: false }.freeze

      # The canvas the widget is drawn around, and the fallback for a stored size
      # it no longer supports.
      class_attribute :_default_size, default: SIZES.first, **ATTRIBUTE_OPTIONS

      # Which sizes a USER may choose, defaulting to all of them. Declare a subset
      # when the widget has nothing to fill the others with — a bare figure at
      # `large` is a title, a number and most of a 2x2 cell of whitespace.
      #
      # DECLARED rather than inferred from the data. Inferring "this widget has no
      # series, so hide `large`" would mean loading every widget just to render a
      # picker — collapsing the `visible?` / data split that lets a picker list
      # the authorized set without running a single query. It would also make the
      # offered sizes vary with the data: a widget whose series is empty this week
      # would silently stop offering a size the user had already chosen. Apple
      # declares `supportedFamilies` for the same reasons.
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

      class << self
        # Validated at class-definition time, so a typo is a boot failure rather
        # than a KeyError the first time someone opens the dashboard.
        #
        # Deliberately does NOT check `_supported_sizes`: `ValueBase` ships with
        # `[:small]`, so a widget widening it writes `default_size :medium` above
        # `supports :small, :medium` and the check would reject a legitimate
        # class. `supports` validates the pair instead, which makes the two
        # ORDER-DEPENDENT — `supports` must come second. The generator scaffolds
        # them that way round.
        def default_size(name = nil)
          return _default_size if name.nil?

          raise ArgumentError, "unknown widget size #{name.inspect}" unless SIZES.include?(name)

          self._default_size = name
        end

        # NOT `sizes`, which sits one letter from `size`. Echoes the
        # `supportedFamilies` this model is adapted from.
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

        # `Widgets::LowStockItems` -> `"low_stock_items"`, which is also the i18n
        # scope and the persisted key. One fewer constant to keep in sync.
        def key
          @key ||= name.demodulize.underscore
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

      # Overridden by the host. Bali owns the HOOK and never the rule: roles,
      # tenancy and feature flags are things only the host can see.
      def visible? = true

      # ---- what the card asks -------------------------------------------------
      #
      # Every one of these is a null here. A pattern overrides what it has, so the
      # card reads one interface and never asks what kind of widget it holds.

      def count = 0

      def items = []

      def view_all_path
        safely(nil) { _view_all_path && instance_exec(&_view_all_path) }
      end

      def trend = nil

      def series = nil

      def goal = nil

      # The headline as printed. A ~215px tile at `text-4xl` fits four to six
      # characters, so a raw 1_234_567 runs off it.
      #
      # A widget formats by overriding `formatted_value`, NOT this — everything
      # a host writes has to run inside the failure net, and the documented
      # idiom (`"$#{Widget.abbreviate(value)}"`) reaches straight past `count`
      # to the abstract method underneath it. Overriding `display_value` itself
      # would put host code outside `safely`, where a raising widget takes the
      # page down instead of degrading its own tile.
      def display_value = safely("—") { formatted_value }

      # What the headline says, before the net. Override this.
      def formatted_value = Widget.abbreviate(count)

      def size = @size || self.class.default_size

      # This widget at a user-chosen size. Always a COPY, because `_default_size`
      # is a class attribute: assigning it would resize the widget for every user
      # in the process until the next deploy.
      #
      # A size this widget does not offer falls back to its default rather than
      # raising — the name arrives from a database column, so it can describe a
      # size retired between the save and the read, and a dashboard that will not
      # render is a worse answer than one drawn at its default.
      def with_size(name)
        chosen = name&.to_sym

        dup.tap { |widget| widget.size = supported_sizes.include?(chosen) ? chosen : size }
      end

      # ONE widget's failure must not take the page with it. A tile that vanishes
      # reads as "nothing to see", which is the one thing a failure must not say,
      # so a raising widget renders the degraded card instead.
      #
      # A PLAIN READER. `Bali::Widget::Component#before_render` does the loading,
      # because deciding what a canvas needs read is the card's job and not the
      # widget's — and the card branches on failure before it would otherwise
      # have asked for anything.
      def failed? = @failed.present?

      # "3 left · Cocina". Here rather than reached through `Bali::Widget` so a
      # row block can call it bare.
      def subtitle(*parts) = Widget.subtitle(*parts)

      protected

      attr_writer :size

      private

      # Wraps every data read a pattern makes. Memoises the FAILURE as well as
      # guarding the call: the card asks `count`, `items` and `view_all_path`
      # separately, and a rescue that did not remember would re-run the raising
      # query three times per tile.
      #
      # The SUCCESSES are memoised by the patterns themselves (`@count ||=`),
      # and have to be: one card asks `count` five times — the headline, the
      # empty state, the "view all" link and its label — and `display_value`
      # reaches it from inside the widget, where no memo in the card can see the
      # call. A widget is built per render, so the memo lives exactly as long as
      # the answer is good for.
      #
      # `NotImplementedError` is named explicitly because it descends from
      # `ScriptError`, NOT `StandardError` — a widget that forgets an abstract
      # method is the most likely way to author a broken one, and the case the
      # safety net most has to cover.
      def safely(fallback)
        return fallback if @failed

        yield
      rescue StandardError, NotImplementedError => e
        raise if Widget.raise_load_errors?

        @failed = e
        report_failure(e)
        fallback
      end

      # Tagged by widget key so an error reporter groups these per tile rather
      # than piling every widget's failure under one controller action.
      def report_failure(error)
        Sentry.capture_exception(error, tags: { widget: failure_tag }) if defined?(Sentry)
        Rails.logger.error(
          "[bali/widget] #{failure_tag} failed to load — #{error.class}: #{error.message}\n" \
          "#{error.backtrace&.first(5)&.join("\n")}"
        )
      end

      # `key` raises for an anonymous class, which is CORRECT for `key` — it is
      # the i18n scope and the persisted `widget_key`. But this is the reporting
      # path, already inside a rescue, and an exception here would mask the
      # failure it exists to record.
      def failure_tag
        key
      rescue StandardError
        self.class.name || "anonymous"
      end
    end
  end
end
