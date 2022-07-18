# frozen_string_literal: true

module Bali
  module PathHelper
    # Returns true when the path matches the current path depending on the match type
    # Available match types are
    # - exact: Matches the whole path
    # - partial: Matches if the path is included in the current path
    # - starts_with: Matches if the current path starts with the path
    #
    # @param path [String] represents the path for the link
    # @param current_path [String] currently active URL
    # @param match [Symbol] one of 3 match types [:exact, :partial, :starts_with]
    def active_path?(path, current_path, match: :exact)
      return false if current_path.nil?

      path_without_params = path.split('?').first
      current_request_path = current_path.gsub(/\.html$/, '')

      case match
      when :starts_with
        current_request_path.starts_with?(path)
      when :partial
        current_request_path.include?(path)
      else
        path_without_params == current_request_path
      end
    end
  end
end
