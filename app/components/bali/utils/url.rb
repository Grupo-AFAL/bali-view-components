# frozen_string_literal: true

module Bali
  module Utils
    module Url
      # Sets `name` to `value` in the URL's query string, replacing whatever
      # value that name already had.
      #
      # The name is normalized to a String before merging because
      # `Rack::Utils.parse_query` returns String keys: merging a Symbol key left
      # BOTH entries in the hash and `to_query` emitted the param twice
      # (`?view=grid&view=table`), which Rack resolves last-wins — so the value
      # already in the URL silently beat the one being set (#653).
      def add_query_param(url, name, value)
        uri = URI(url)
        query_params = Rack::Utils.parse_query(uri.query.to_s).merge(name.to_s => value)
        query_params.each do |key, param_value|
          if !array_query_params?(key) && param_value.is_a?(Array)
            query_params[key] = param_value.first
          end
        end
        uri.query = query_params.to_query
        uri.to_s
      end

      private

      def array_query_params?(query_param_name)
        query_param_name.ends_with?("[]") ||
          %w[_in _not_in].any? { |predicate| query_param_name.ends_with?(predicate) }
      end
    end
  end
end
