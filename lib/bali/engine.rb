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
      #{root}/app/controllers
      #{root}/app/helpers
      #{root}/app/lib
      #{root}/app/widgets
      #{root}/app/models
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

    # `before: :load_environment_config` mirrors Rails' own "active_support.deprecator":
    # `active_support.deprecation_behavior` applies config.active_support.deprecation to
    # whatever is registered by then, and plain engine initializers run after it.
    initializer "bali.deprecator", before: :load_environment_config do |app|
      app.deprecators[:bali] = Bali.deprecator
    end

    initializer "Register Bali ActiveModel::Types" do
      ActiveModel::Type.register(:date_range, Bali::Types::DateRangeValue)
    end

    # isolate_namespace keeps engine helpers out of the host app, but the
    # island meta-tag helpers are meant for the HOST layout (they publish the
    # digested paths of the app's own island bundles), so expose just those.
    #
    # to_prepare, NOT on_load(:action_controller_base): a host that loads
    # ActionController::Base during boot (any gem requiring it does) fires that
    # hook before Zeitwerk is set up, and the constant raises NameError. The
    # dummy app never loads it that early, so only real hosts crashed.
    config.to_prepare do
      ActionController::Base.helper(Bali::ReactIslandHelper)
      ActionController::Base.helper(Bali::BlockEditorHelper)
    end

    # Host-injected controller concerns (#710) — see docs/guides/engines.md. In a
    # to_prepare the constant resolves to the freshly-loaded class, so the include
    # survives code reloads in development; the `<` guard keeps a repeated prepare
    # pass from re-firing a plain module's `included` hook on the same class. Rails
    # runs :run_prepare_callbacks BEFORE :eager_load!, so engine controllers defined
    # later inherit whatever the concern registered on the base class.
    config.to_prepare do
      Bali.engine_controller_concerns.each do |concern|
        Bali::ApplicationController.include(concern) unless Bali::ApplicationController < concern
      end
    end

    # No initializer adds config/locales here on purpose. Rails::Engine already
    # registers it through `paths["config/locales"]`, in an order that puts every
    # engine BEFORE the app — which is what lets a host override a Bali string.
    # Appending the same files to `i18n.load_path` by hand (what this engine used
    # to do) put them back at the END, after the host's, so I18n's last-one-wins
    # made the gem beat the app and no host override ever took effect.
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
