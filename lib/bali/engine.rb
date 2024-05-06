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

    initializer 'Bali precompile hook' do |app|
      if defined?(Sprockets)
        [
          root.join('app', 'components'),
          root.join('app', 'assets', 'javascripts')
        ].each do |dir_path|
          Dir[File.join(dir_path, 'bali', '**', '*.js')].each do |path|
            app.config.assets.precompile << path.gsub("#{dir_path.to_path}/", '')
          end

          Dir[File.join(dir_path, 'bali', '**', '*.png')].each do |path|
            app.config.assets.precompile << path.gsub("#{dir_path.to_path}/", '')
          end
        end
      end
    end
  end
end
