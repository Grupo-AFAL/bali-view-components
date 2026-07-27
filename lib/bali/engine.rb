# frozen_string_literal: true

require "view_component-contrib"
require "lucide-rails"

module Bali
  class Engine < ::Rails::Engine
    isolate_namespace Bali

    # This ASSIGNMENT (not append) is the engine's complete autoload surface in
    # a host app: any app/ directory missing here resolves to NameError there.
    # Do not trust the dummy suite to catch an omission — Lookbook pushes engine
    # dirs into the dummy's autoloader, so constants resolve in this repo that
    # do not resolve in a real host (Bali::BlockEditorHelper broke every host
    # boot in v2.17.0 while 2860 tests stayed green here).
    config.eager_load_paths = %W[
      #{root}/app/components
      #{root}/app/helpers
      #{root}/app/lib
    ]

    overrides = File.expand_path(
      File.join(File.dirname(__FILE__), "overrides", "**", "*_override.rb")
    )
    config.to_prepare { Dir.glob(overrides).each { |override| load override } }

    initializer "bali.exclude_previews_from_eager_load" do
      Rails.autoloaders.each do |autoloader|
        autoloader.do_not_eager_load(Dir[root.join("app/components/**/preview.rb")])
      end
    end

    config.generators do |g|
      g.test_framework :minitest, fixture: true
      g.helper false
    end

    ActiveSupport.on_load(:view_component) do
      ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
      ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract
    end

    initializer "Register Bali ActiveModel::Types" do
      ActiveModel::Type.register(:date_range, Bali::Types::DateRangeValue)
    end

    # isolate_namespace keeps engine helpers out of the host app, but
    # block_editor_meta_tags is meant for the HOST layout (it publishes the
    # digested paths of the app's own editor bundle), so expose just that one.
    #
    # to_prepare, NOT on_load(:action_controller_base): a host that loads
    # ActionController::Base during boot (any gem requiring it does) fires that
    # hook before Zeitwerk is set up, and the constant raises NameError. The
    # dummy app never loads it that early, so only real hosts crashed.
    config.to_prepare do
      ActionController::Base.helper(Bali::BlockEditorHelper)
    end

    initializer "bali.add_locales" do |app|
      app.config.i18n.load_path += Dir[root.join("config", "locales", "*.yml")]
    end

    initializer "Bali add assets paths", before: :append_assets_path do |app|
      # Add Bali's JavaScript and component paths for both Propshaft and Sprockets
      app.config.assets.paths << root.join("app", "components")
      app.config.assets.paths << root.join("app", "assets", "javascripts")
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
      # Add frontend path for consuming apps using bundlers (esbuild, Vite, etc.)
      app.config.assets.paths << root.join("app", "frontend")
    end

    initializer "Bali precompile hook" do |app|
      if defined?(Sprockets)
        [
          root.join("app", "components"),
          root.join("app", "assets", "javascripts")
        ].each do |dir_path|
          Dir[File.join(dir_path, "bali", "**", "*.js")].each do |path|
            app.config.assets.precompile << path.gsub("#{dir_path.to_path}/", "")
          end

          Dir[File.join(dir_path, "bali", "**", "*.png")].each do |path|
            app.config.assets.precompile << path.gsub("#{dir_path.to_path}/", "")
          end
        end
      end
    end
  end
end
