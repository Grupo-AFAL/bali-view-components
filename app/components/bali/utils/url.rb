# frozen_string_literal: true

module Bali
  module Utils
    module Url
      def add_query_param(url, name, value)
        add_query_params(url, { name => value })
      end

      def add_query_params(url, values = {})
        uri = URI(url)
        uri.query ||= ''
        uri.query += values.map { |k, v| "#{k}=#{v}" }.join('&')
        uri.to_s
      end
    end
  end
end
