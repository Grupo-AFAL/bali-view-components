module Bali
  module Utils
    module Url
      def add_query_param(url, name, value)
        uri = URI(url)
        uri.query ||= ''
        uri.query += "#{name}=#{value}"
        uri.to_s
      end
    end
  end
end
