# frozen_string_literal: true

require "pagy/toolbox/helpers/support/series"

module Bali
  module Pagination
    # The one place in Bali that talks to Pagy.
    #
    # Two of the things a paginator needs are not on Pagy's public surface: `series` — the
    # `[1, :gap, 7, "8", 9, :gap, 36]` list the buttons are built from — is `protected`, and
    # the request a Pagy was built with lives in an ivar with no reader. Reaching for either
    # one from a component meant every Pagy upgrade broke whichever page happened to render
    # first, with no test in between. Contained here, an upgrade breaks this class's own
    # tests instead, and there is exactly one file to fix.
    #
    # It also owns the summary sentence, because "Showing 1-10 of 47 movies" is nothing but
    # the same numbers in a string: deriving it in each component separately is how the
    # library ended up with two i18n keys for one sentence, only one of which was translated.
    class PagyAdapter
      # Pagy only builds URLs when it was created through the `pagy()` helper, which injects
      # the request. A bare `Pagy::Offset.new` — every Lookbook preview, every unit test, any
      # host that builds one by hand — has none, and `page_url` blows up on the nil request.
      # `base_url` covers that, and when a host passes one it wins outright: a parameter that
      # is silently ignored is worse than one that is not accepted at all (#654).
      #
      # `fragment` is appended to every link, so a paginator halfway down a page can keep the
      # reader where they were instead of jumping to the top.
      def initialize(pagy, base_url: nil, fragment: nil)
        @pagy = pagy
        @base_url = base_url.presence
        @fragment = fragment.presence
      end

      def pages = @pagy.pages
      def current_page = @pagy.page
      def previous_page = @pagy.previous
      def next_page = @pagy.next
      def count = @pagy.count
      def from = @pagy.from
      def to = @pagy.to

      # More than one page to move between. Below that there is nothing to click.
      def navigable? = pages > 1

      # Zero results have no range to describe. "Showing 0-0 of 0 movies" is what the library
      # printed on an empty search, and it says nothing a host would want to say.
      #
      # `to_i` covers countless pagination, where `count` is nil by design — "of nil" is not a
      # sentence either, and the old code interpolated it into one.
      def summarizable? = count.to_i.positive?

      def summary(item_name = nil)
        I18n.t(
          "bali_view.pagination.summary",
          from: from,
          to: to,
          count: count,
          item_name: resolved_item_name(item_name)
        )
      end

      # Integer for a linkable page, String for the current one, :gap for an elision.
      # `protected` in Pagy 43.6 — see the class comment.
      def series
        @pagy.send(:series)
      end

      def page_url(page)
        return @pagy.page_url(page, **pagy_url_options) if @base_url.nil? && linkable?

        compose_page_url(page)
      end

      # Whether Pagy can build its own URLs, i.e. whether it carries a request.
      def linkable?
        !@pagy.instance_variable_get(:@request).nil?
      end

      private

      # "1 items" is not a sentence, and the count is already right there in the call.
      #
      # Symbol → an i18n key, resolved with `count:` — Rails' full CLDR plural rules, for
      #   locales that go beyond one/other.
      # Hash   → `{one:, other:}` picked by count. Enough for es/en, no locale file needed.
      # String → used verbatim, invariant with the count: the behaviour every existing call
      #   site already has.
      # nil/"" → the gem's default, which is a plural hash now, so it pluralizes too.
      def resolved_item_name(item_name)
        case item_name
        when Symbol then I18n.t(item_name, count: count)
        when Hash   then item_name[count == 1 ? :one : :other] || item_name[:other]
        else item_name.presence || I18n.t("bali_view.pagination.default_item_name", count: count)
        end
      end

      def pagy_url_options
        @fragment ? { fragment: @fragment } : {}
      end

      # The fallback: what Pagy's own `compose_page_url` does, minus the request it does not
      # have. Keep whatever query string the base already carries, swap the page key, and
      # append the fragment the way Pagy does (conditionally prepending '#'). With no base at
      # all the result is a bare `?page=2`, which the browser resolves against the current
      # path — the same place the old `request.path` fallback pointed at.
      #
      # The page value and the query string are both built by Pagy, not by Rack, because for
      # countless pagination the value is not the page number: it is `"3+2"`, the page plus
      # the last page Pagy knows about, wrapped in a `Pagy::EscapedValue` so the `+` survives
      # into the URL. `Rack::Utils.build_nested_query` escapes it to `3%2B2` and the link
      # loses the half Pagy needs on the way back.
      def compose_page_url(page)
        uri = URI.parse(@base_url.to_s)
        params = Rack::Utils.parse_nested_query(uri.query || "")
        params[page_key] = @pagy.send(:compose_page_param, page)
        uri.query = Pagy::Linkable::QueryUtils.build_nested_query(params)

        "#{uri}#{@fragment&.sub(/\A(?=[^#])/, '#')}"
      end

      def page_key
        @pagy.options[:page_key] || "page"
      end
    end
  end
end
