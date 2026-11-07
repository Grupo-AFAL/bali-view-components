# frozen_string_literal: true

module Bali
  # The Ransack parameter a quick text search submits, built in one place.
  #
  # Four call sites used to spell this string out by hand -- FilterForm, the
  # Filters panel, SimpleFilters and SavedViews -- each repeating the `_or_`
  # join and the predicate suffix. They agreed by convention only: a listing
  # whose SavedViews shortcut disagreed with its search box searched a
  # different set of columns than the one the placeholder advertised, and
  # nothing in the stack could tell.
  #
  # It is also the one place that decides which variant of the text predicates Bali writes
  # (#1530). Up to ransack 5, `cont`, `start` and `end` already ignore case on PostgreSQL
  # (ILIKE); ransack 6 makes them case-sensitive there (ransack#1715) and adds `i_start` and
  # `i_end` beside `i_cont`. Under 5 Bali reads and writes the plain ones, as it always did:
  # nothing an app on 5 produces carries an `i_` one, and reading it would hand Ransack a search
  # the app's own guards never see. Under 6 it writes the `i_` ones and reads both, for the
  # bookmarks and saved views written before.
  module RansackParamName
    # Each text predicate Bali writes, and its case-insensitive twin.
    CASE_INSENSITIVE = {
      "cont" => "i_cont", "not_cont" => "not_i_cont", "start" => "i_start", "end" => "i_end"
    }.freeze

    class << self
      # Whether the installed ransack is 6 or later, asked of the gem's own predicates, so an
      # app's `add_predicate "i_start"` does not flip it.
      def case_insensitive_text?
        return @case_insensitive_text if defined?(@case_insensitive_text)

        @case_insensitive_text = Ransack::Constants::DERIVED_PREDICATES.assoc("i_start").present?
      end

      # The variant of a text predicate this ransack gets from Bali: itself under ransack 5, its
      # `i_` twin under 6.
      #
      # @param predicate [String] "cont", "not_cont", "start" or "end", or one of their `i_`
      #   twins; anything else comes back as it is
      # @return [String] e.g. "cont" => "cont" under ransack 5, "i_cont" under 6
      def text_predicate(predicate)
        predicate = predicate.to_s
        case_insensitive_text? ? CASE_INSENSITIVE.fetch(predicate, predicate) : predicate
      end

      # The bare Ransack predicate, which is what goes inside `q`.
      #
      # @param fields [Array<Symbol, String>, Symbol, String, nil]
      # @return [String, nil] e.g. [:name, :genre] => "name_or_genre_cont" (`_i_cont` under
      #   ransack 6)
      def predicate(fields)
        joined(fields, text_predicate("cont"))
      end

      # The quick search as it was written before ransack 6, which a bookmark, a link an app
      # built by hand or a saved shortcut may still carry. nil under ransack 5, where it is
      # `predicate` itself.
      #
      # @param fields [Array<Symbol, String>, Symbol, String, nil]
      # @return [String, nil] e.g. [:name, :genre] => "name_or_genre_cont" under ransack 6
      def alternate_predicate(fields)
        joined(fields, "cont") if case_insensitive_text?
      end

      # The full input name a form submits.
      #
      # @param fields [Array<Symbol, String>, Symbol, String, nil]
      # @return [String, nil] e.g. [:name, :genre] => "q[name_or_genre_cont]"
      def param(fields)
        name = predicate(fields)
        name && "q[#{name}]"
      end

      private

      def joined(fields, matcher)
        names = Array(fields).map(&:to_s).reject(&:empty?)
        return nil if names.empty?

        "#{names.join('_or_')}_#{matcher}"
      end
    end
  end
end
