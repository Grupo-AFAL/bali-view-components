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
    # A WIDGET RAISES. It does not rescue itself, does not report, and has no
    # `failed?` — `Bali::Widget::Component` is an ERROR BOUNDARY around one
    # tile, and that is where a failure is caught, reported and turned into the
    # degraded card.
    #
    # The rescue is a RENDERING concern: "one tile must not take the page down"
    # is a fact about a page of twelve tiles, and a widget knows nothing about
    # being one of them. `Movie.count` raising is ordinary, and `Movie` does not
    # rescue itself either.
    #
    # Everything awkward about the alternative came from the widget swallowing:
    # a `failed?` that answered wrong until something had been read, a `#load` to
    # make it answer right, five per-pattern versions of that once `count` turned
    # out not to mean "resolved", a fallback value on every read so a half-dead
    # widget kept answering, and a `defined?` memo dance because a legitimate nil
    # was indistinguishable from a swallowed failure. A boundary deletes all of
    # it: the widget raises, and the card decides what a page does about it.
    #
    # THE PATTERN IS THE TYPE. A widget picks exactly one of `ValueBase`,
    # `ListBase`, `TrendBase`, `ProgressBase` or `CheckBase`, and that is not a claim it
    # can contradict — it is what gives the class its declarations. Choosing
    # `TrendBase` and not declaring `t.current` is a loud failure, not a card that
    # renders half a thing.
    class Base
      # Every declaration below is CLASS-level configuration. The instance writer
      # `class_attribute` generates by default silently shadows the class value
      # for one object — the same trap `#with_size` dups to avoid, reachable
      # through another door — and the predicate is noise on forty-eight methods
      # nothing calls. Instance READERS stay: the patterns read them.
      ATTRIBUTE_OPTIONS = { instance_writer: false, instance_predicate: false }.freeze

      # THE BUILDER CONTRACT, which every `list`/`row`/`series`/`trend`/`goal`
      # declaration relies on and none of them restates:
      #
      #   1. A builder is held in a `class_attribute` and `dup`ed before it is
      #      written to. `class_attribute` copies on WRITE and never on MUTATION,
      #      so without the dup a subclass would be handed its parent's object and
      #      two siblings would overwrite each other's fields — last class body
      #      loaded winning, which presents as "widget B shows widget A's title"
      #      and depends on autoload order.
      #
      #   2. That `dup` is SHALLOW, and shallow is sufficient only because every
      #      setter ASSIGNS (`@title = block || value`) rather than mutating, and
      #      no builder exposes a reader. This is a proof obligation, not a
      #      shortcut: add an accumulating field (`r.tag <<`) or a reader that
      #      hands out the ivar, and parent and child start sharing one object
      #      through the copy. Add a `dup` of your own to the field if you do.
      #
      # `test/bali/widget/patterns_test.rb` pins (1) for all four builders.

      # The canvas the widget is drawn around, and the fallback for a stored size
      # it no longer supports.
      class_attribute :_default_size, default: SIZES.first, **ATTRIBUTE_OPTIONS

      # Which sizes a USER may choose, defaulting to all of them. Declare a subset
      # when the widget has nothing to fill the others with — a bare figure at
      # `large` is a title, a number and most of a 2x2 cell of whitespace.
      #
      # DECLARED rather than inferred from the data. Inferring "this widget has no
      # series, so hide `large`" would mean loading every widget just to render a
      # picker — collapsing the `authorized?` / data split that lets a picker list
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

      # MAY THIS OWNER SEE THIS WIDGET? Overridden by the host. Bali owns the
      # hook and never the rule: roles, tenancy and feature flags are things
      # only the host can see.
      #
      #   def authorized? = context.has_any_role?(:finance)
      #
      # NOT `authorized?`, which is what this was called and which named the wrong
      # thing. Three boundaries ask this — `Store`, `Layout.from` and
      # `Layout.chosen` — and none of them is asking "should this be on screen".
      # They are asking whether the widget may be persisted, offered and
      # rendered at all. A host reading `authorized?` could reasonably write a
      # presentation condition into it and be surprised that it also governs
      # what the database will accept.
      #
      # It may QUERY — the dummy app's `ActiveStudios` runs one `EXISTS` — but it
      # must not run this widget's own DATA queries. That split is what lets a
      # picker list thirty widgets without loading thirty widgets. Bali calls it
      # once or twice per request and does not memoise for you: the default here
      # is a constant, and a host whose rule is expensive knows that where Bali
      # cannot.
      def authorized? = true

      # ---- what every widget has -----------------------------------------------

      # WHERE THE TILE LINKS. A figure, a trend, a ring and a check all link
      # somewhere just as a list does, and no pattern overrides this — it is the
      # implementation rather than a default.
      def view_all_path = _view_all_path && instance_exec(&_view_all_path)

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

      protected

      attr_writer :size
    end
  end
end
