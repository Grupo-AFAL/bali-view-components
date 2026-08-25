# frozen_string_literal: true

module Bali
  module Widget
    # Shared chrome for dashboard widgets. A host subclass owns one widget: its
    # semantic `sized`, its `visible?` rule, and a `#call` returning a `Result`.
    #
    # Visibility and loading are deliberately SEPARATE halves. `visible?` costs
    # only whatever the host's predicate costs, so a picker can list every
    # authorized widget without running a single widget query; `#result` is the
    # load, and only the widgets that survive `Layout#widgets` are ever asked
    # for it.
    #
    # Bali owns the `visible?` HOOK and never the rule — roles, tenancy and
    # feature flags are things only the host can see.
    class Base
      # How many preview rows every widget loads, regardless of the size it is
      # rendered at. `count` comes from the full scope, so the preview is
      # presentation rather than data — which is what keeps `#call` from needing
      # to know a size. `Widget::Component` truncates to what the size has room
      # for.
      PREVIEW_ROWS = 8

      # No default, deliberately: a widget that forgets its size should fail
      # loudly rather than inherit one its layout was never drawn around.
      class_attribute :size

      # Widget copy is HOST content, not Bali's. Bali's own chrome lives under
      # `bali_view.widgets.*`; this is the scope a host's titles live in.
      class_attribute :i18n_scope, default: "widgets"

      class << self
        # Validated at class-definition time, so a typo is a boot failure rather
        # than a KeyError the first time someone opens the dashboard.
        def sized(name)
          raise ArgumentError, "unknown widget size #{name.inspect}" unless SIZES.include?(name)

          self.size = name
        end

        # `Widgets::LowStockItems` -> `"low_stock_items"`, which is also the
        # i18n scope and the persisted key. One fewer constant to keep in sync.
        def key
          @key ||= name.demodulize.underscore
        end

        def title = I18n.t("#{i18n_scope}.#{key}.title")

        # The `small` card is ~215px wide, where a long title wraps to three
        # lines. Falls back to the full title, so a widget only needs a short one
        # if its real one doesn't fit.
        def short_title = I18n.t("#{i18n_scope}.#{key}.short_title", default: title)

        # One line telling a picker what this widget actually shows. Several
        # titles are usually near-neighbours, so the label alone doesn't
        # distinguish them.
        def description = I18n.t("#{i18n_scope}.#{key}.description")

        # Empty-state copy, shown by the card's list body.
        def empty_message = I18n.t("#{i18n_scope}.#{key}.empty")
      end

      # `context` is whatever the host needs to gate and scope on — a Pundit
      # context, a user, a tenant, nothing at all. Bali never reads it.
      def initialize(context = nil)
        @context = context
      end

      delegate :key, :title, :short_title, :description, :empty_message, to: :class
      # The component receives the WIDGET, not its `Result`, so `widget.count` is
      # true rather than a convenient lie — and the widget still knows its own
      # key, which is what lets one component derive every widget's copy.
      delegate :count, :items, :view_all_path, :payload, :failed?, to: :result

      # Overridden by the host. Bali's default shows everything.
      def visible? = true

      # This widget rendered at a user-chosen size. Always a COPY, because `size`
      # is a `class_attribute`: assigning it on the class would resize that
      # widget for every user in the process until the next deploy. The instance
      # writer shadows the class value on this object alone.
      #
      # An unknown name falls back to the size the widget was drawn around rather
      # than raising — the name arrives from a database column, so it can
      # describe something retired between the save and the read, and a dashboard
      # that will not render is a worse answer than one drawn at its default.
      #
      # A copy even when nothing changes, so callers get one kind of thing back.
      def with_size(name)
        chosen = name&.to_sym

        dup.tap { |widget| widget.size = SIZES.include?(chosen) ? chosen : size }
      end

      def result
        @result ||= load_result
      end

      private

      attr_reader :context

      # ONE widget's failure must not take the page with it. Memoizing
      # `load_result` rather than `call` is load-bearing: the failure has to be
      # memoized too, because the component delegates `count`, `items` and
      # `view_all_path` separately and a rescue that returned without assigning
      # would re-run the raising query three times per card.
      #
      # `NotImplementedError` is named explicitly because it descends from
      # `ScriptError`, NOT `StandardError` — so a subclass that forgets `#call`
      # would otherwise sail straight past this rescue and take the page down in
      # production, which is the single most likely way to author a broken widget
      # and the one case the safety net has to cover.
      def load_result
        call
      rescue StandardError, NotImplementedError => e
        raise if Widget.raise_load_errors?

        report_failure(e)
        Result.failed
      end

      # Tagged by widget key so Sentry groups these per tile rather than piling
      # every widget's failure under one controller action.
      def report_failure(error)
        Sentry.capture_exception(error, tags: { widget: failure_tag }) if defined?(Sentry)
        Rails.logger.error(
          "[bali/widget] #{failure_tag} failed to load — #{error.class}: #{error.message}\n" \
          "#{error.backtrace&.first(5)&.join("\n")}"
        )
      end

      # `key` raises for an anonymous class, which is CORRECT for `key` — it is
      # the i18n scope and the persisted `widget_key`, where a silent fallback
      # would collide. But this is the reporting path, already inside a rescue,
      # and an exception here would mask the failure it exists to record.
      def failure_tag
        key
      rescue StandardError
        self.class.name || "anonymous"
      end

      def call
        raise NotImplementedError
      end

      # The shape most list widgets share: the count is the WHOLE scope, the rows
      # are a capped preview of it, and `#row` turns each record into a `Row`.
      #
      # The scope must arrive ORDERED: paging a preview off an unordered relation
      # is a different bug in every database.
      def list_from(scope, view_all_path: nil)
        Result.new(
          count: scope.count,
          items: scope.limit(PREVIEW_ROWS).map { |record| row(record) },
          view_all_path: view_all_path
        )
      end

      def subtitle(*parts)
        Widget.subtitle(*parts)
      end

      # Reached through `helpers` rather than by including `DateHelper`: this
      # object is handed to the component, and its public surface is deliberately
      # curated by the `delegate`s above. An include would add ~17 public methods
      # to it, several of which raise outside a view.
      def time_ago_in_words(time)
        ActionController::Base.helpers.time_ago_in_words(time)
      end
    end
  end
end
