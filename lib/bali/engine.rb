# frozen_string_literal: true

require 'view_component-contrib'

module Bali
  class Engine < ::Rails::Engine
    isolate_namespace Bali

    config.eager_load_paths = %W[
      #{root}/app/components
      #{root}/app/lib
    ]

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.view_specs      false
      g.routing_specs   false
      g.helper          false
    end

    ActiveSupport.on_load(:view_component) do
      ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
      ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract
    end

    initializer 'Bali add app/components to assets paths' do |app|
      app.config.assets.paths << "#{root}/app/components"
    end
  end
end
