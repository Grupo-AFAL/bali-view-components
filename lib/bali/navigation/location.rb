# frozen_string_literal: true

module Bali
  class Navigation
    # Where a controller belongs: what `Bali::Navigation.locate` answers. Any member is nil when
    # the claim that won sits above it — a module claiming a namespace places no item. The group,
    # when there is one, is `item.parent`.
    Location = Data.define(:app_module, :section, :item) do
      def self.for(node)
        new(app_module: node.app_module, section: node.section, item: (node if node.item?))
      end
    end
  end
end
