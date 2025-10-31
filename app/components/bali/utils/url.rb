# frozen_string_literal: true

module Bali
  module Utils
    module Url
      def add_query_param(url, name, value)
        add_query_params(url, { name => value })
      end

      def add_query_params(url, values = {})
        uri = URI(url)
        query_params = CGI.parse(uri.query.to_s).merge(values)
        query_params.each do |key, value|
          query_params[key] = value.first if !array_query_params?(key) && value.is_a?(Array)
        end
        uri.query = query_params.to_query
        uri.to_s
      end

      private

      def array_query_params?(query_param_name)
        query_param_name.ends_with?('[]') ||
          %w[_in _not_in].any? { |predicate| query_param_name.ends_with?(predicate) }
      end
    end
  end
end
