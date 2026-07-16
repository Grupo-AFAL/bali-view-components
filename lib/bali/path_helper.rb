# frozen_string_literal: true

module Bali
  module PathHelper
    # Returns true when the path matches the current path depending on the match type
    # Available match types are
    # - exact: Matches the whole path
    # - partial: Matches if the path is included in the current path
    # - starts_with: Matches if the current path starts with the path
    # - crud: Matches the HREF for any CRUD action.
    #
    # @param path [String] represents the path for the link
    # @param current_path [String] currently active URL
    # @param match [Symbol] one of 4 match types [:exact, :partial, :starts_with, :crud]
    def active_path?(path, current_path, match: :exact)
      return false if current_path.nil?

      path_without_params = path.split("?").first
      current_request_path = current_path.split("?").first.gsub(/\.html$/, "")

      case match
      when :crud
        path_without_params == current_request_path ||
          new_or_show_or_edit_path?(path, current_request_path)
      when :starts_with
        current_request_path.starts_with?(path)
      when :partial
        current_request_path.include?(path)
      else
        path_without_params == current_request_path
      end
    end

    # Returns true when any +active_when+ matcher matches the current path.
    # Complements +active_path?+ so an item can stay highlighted on nested
    # full-page routes (e.g. /departments/1/merges/new) without the
    # over-matching of +:starts_with+, which would also light up unrelated
    # siblings that share the prefix.
    #
    # Matchers may be a String prefix, a Regexp, a Proc/lambda (called with
    # the normalized current path), or an Array mixing any of these.
    #
    # @param active_when [String, Regexp, Proc, Array, nil] extra matcher(s)
    # @param current_path [String] currently active URL
    def active_extra_path?(active_when, current_path)
      return false if current_path.nil? || active_when.blank?

      current_request_path = current_path.split("?").first.gsub(/\.html$/, "")

      Array(active_when).any? do |matcher|
        case matcher
        when Regexp
          matcher.match?(current_request_path)
        when Proc
          matcher.call(current_request_path)
        else
          matcher.present? && current_request_path.start_with?(matcher.to_s)
        end
      end
    end

    private

    def new_or_show_or_edit_path?(path, current_request_path)
      %r{\A#{path}/([[:digit:]]+(/edit)?|new)\Z}.match(current_request_path)
    end
  end
end
