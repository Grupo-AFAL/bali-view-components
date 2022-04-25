# frozen_string_literal: true

module Bali
  module ImageGrid
    class Component < ApplicationViewComponent
      renders_many :images, Image::Component
    end
  end
end
