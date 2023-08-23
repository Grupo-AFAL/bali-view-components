module Bali
  module TestsHelper
    def custom_dom_id(model)
      "#{model.model_name.singular_route_key}_#{model.id}"
    end
  
    def turbo_stream_headers(headers = {})
      headers.merge(Accept: %i[turbo_stream html].map { |type| Mime[type].to_s }.join(', '))
    end
  end
end