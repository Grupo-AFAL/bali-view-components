# frozen_string_literal: true

module Bali
  module SideMenu
    class Component < ApplicationViewComponent
      renders_many :lists, List::Component

      def initialize(**options)
        @options = options
      end
    end
  end
end
