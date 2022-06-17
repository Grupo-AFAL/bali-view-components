# frozen_string_literal: true

module Bali
  module Loader
    class Component < ApplicationViewComponent
      attr_reader :text

      def initialize(text: 'Loading...')
        @text = text
      end
    end
  end
end