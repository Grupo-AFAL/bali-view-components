# frozen_string_literal: true

module Bali
  module DeleteLink
    class Preview < ApplicationViewComponentPreview
      def default(name: 'Eliminar', href: 'Elminar')
        render DeleteLink::Component.new(name: name, href: href)
      end
    
      def with_hovercard(disabled_hover_url: '#', href: 'some_path', disabled: true)
        render DeleteLink::Component.new(
          href: href,
          disabled: disabled,
          disabled_hover_url: disabled_hover_url) 
        # render_with_template(
        #   template: 'delete_link/previews/default',
        #   locals: {
        #     disabled_hover_url: disabled_hover_url,
        #     href: href,
        #     disabled: disabled
        #   }
        # )
      end
    end
  end
end
