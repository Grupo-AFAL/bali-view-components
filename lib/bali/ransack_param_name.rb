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
  module RansackParamName
    # Ransack's "contains" matcher. Quick search has always been a substring
    # match over text columns; nothing here has ever been configurable.
    MATCHER = "cont"

    class << self
      # The bare Ransack predicate, which is what goes inside `q`.
      #
      # @param fields [Array<Symbol, String>, Symbol, String, nil]
      # @return [String, nil] e.g. [:name, :genre] => "name_or_genre_cont"
      def predicate(fields)
        names = Array(fields).map(&:to_s).reject(&:empty?)
        return nil if names.empty?

        "#{names.join('_or_')}_#{MATCHER}"
      end

      # The full input name a form submits.
      #
      # @param fields [Array<Symbol, String>, Symbol, String, nil]
      # @return [String, nil] e.g. [:name, :genre] => "q[name_or_genre_cont]"
      def param(fields)
        name = predicate(fields)
        name && "q[#{name}]"
      end
    end
  end
end
