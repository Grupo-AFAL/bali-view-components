# frozen_string_literal: true

# Reload lib/bali files in development when they change
# These files use `require` so Rails doesn't auto-reload them

if Rails.env.development?
  gem_lib_path = Rails.root.parent.parent.join('lib/bali')

  Rails.application.config.after_initialize do
    reloader = ActiveSupport::FileUpdateChecker.new([], { gem_lib_path.to_s => [:rb] }) do
      Rails.logger.info "[Bali] Reloading lib/bali files..."
      Dir[gem_lib_path.join('**/*.rb')].sort.each { |file| load file }
    end

    Rails.application.reloaders << reloader
    Rails.application.reloader.to_run { reloader.execute_if_updated }
  end
end
