# frozen_string_literal: true

require 'view_component-contrib'
require 'lucide-rails'

module Bali
  class Engine < ::Rails::Engine
    isolate_namespace Bali

    config.eager_load_paths = %W[
      #{root}/app/components
      #{root}/app/lib
    ]

    overrides = File.expand_path(
      File.join(File.dirname(__FILE__), 'overrides', '**', '*_override.rb')
    )
    config.to_prepare { Dir.glob(overrides).each { |override| load override } }

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

    ActiveSupport.on_load(:active_record) do
      include Bali::Concerns::GlobalIdAccessors
    end

    initializer 'Register Bali ActiveModel::Types' do
      ActiveModel::Type.register(:date_range, Bali::Types::DateRangeValue)
    end

    initializer 'bali.add_locales' do |app|
      app.config.i18n.load_path += Dir[root.join('config', 'locales', '*.yml')]
    end

    initializer 'Bali add assets paths', before: :append_assets_path do |app|
      # Add Bali's JavaScript and component paths for both Propshaft and Sprockets
      app.config.assets.paths << root.join('app', 'components')
      app.config.assets.paths << root.join('app', 'assets', 'javascripts')
      app.config.assets.paths << root.join('app', 'assets', 'stylesheets')
      # Add frontend path for Vite-based consuming apps
      app.config.assets.paths << root.join('app', 'frontend')
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
