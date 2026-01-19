require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
require 'view_component'

Bundler.require(*Rails.groups)
require 'bali'

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Tijuana'
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # ViewComponents
    config.autoload_paths << Rails.root.parent.parent.join('app/components')
    config.view_component.preview_paths << Rails.root.parent.parent.join('app/components')

    # Watch Ruby/ERB files for preview changes (not JS/SCSS which trigger cascading rebuilds)
    config.lookbook.listen_extensions = %w[js css rb erb]
    config.lookbook.preview_layout = 'lookbook_preview'

    # Performance: disable live updates when not needed
    if ENV['DISABLE_RELOADING']
      config.lookbook.live_updates = false
      config.lookbook.listen = false
    end

    # Documentation pages
    config.lookbook.page_paths = [Rails.root.join("app/views/lookbook/pages")]
  end
end
