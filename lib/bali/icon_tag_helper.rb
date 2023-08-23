module Bali
  module IconTagHelper
    def icon_tag(name, options = {})
      render Bali::Icon::Component.new(name, **options)
    end
  end
end