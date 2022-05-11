# frozen_string_literal: true

module Bali
  module PathHelper
    def active_path?(path, match: :exact)
      path_without_params = path.split('?').first
      current_request_path = request.path.gsub(/\.html$/, '')

      case match
      when :partial
        current_request_path.include?(path)
      else
        path_without_params == current_request_path
      end
    end
  end
end
