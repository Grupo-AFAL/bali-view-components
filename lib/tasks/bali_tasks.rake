# frozen_string_literal: true

require "bali/engine_migrations"

# Per-feature migration installs (#1079). `bali:install:migrations` — defined by
# Rails::Engine's own rake_tasks block, which runs before this file is loaded — copies the
# five migrations the engine ships; these copy one. Rake keeps a task and a namespace of
# the same name apart, so both spellings resolve.
namespace :bali do
  namespace :install do
    namespace :migrations do
      Bali::EngineMigrations.all.each do |feature, path|
        desc "Copy only #{File.basename(path)} from bali to the application"
        task feature => :"db:load_config" do
          Bali::EngineMigrations.install(
            feature,
            destination: Bali::EngineMigrations.destination_for(ENV["DATABASE"]),
            # `proc`, not a lambda: Rails calls on_copy with a third argument (the path the
            # migration had inside the gem) and its own task ignores it the same way.
            on_skip: proc { |name, migration|
              puts "NOTE: Migration #{migration.basename} from #{name} has been skipped. " \
                   "Migration with the same name already exists."
            },
            on_copy: proc { |name, migration|
              puts "Copied migration #{migration.basename} from #{name}"
            }
          )
        end
      end
    end

    # Said where it happens, not only in the guide: every per-feature section of
    # docs/guides/engines.md used to point at the umbrella task, so a host installing one
    # feature only found out it had four extra tables when it read its own schema.rb.
    # No `desc`, so it stays out of `rake -T` — it is a notice, not a task to run.
    task :migrations_notice do
      features = Bali::EngineMigrations.all.keys
      puts "This copies ALL #{features.size} migrations bali ships. To install only one feature:"
      features.each { |feature| puts "  bin/rails bali:install:migrations:#{feature}" }
      puts
    end
  end
end

if Rake::Task.task_defined?("bali:install:migrations")
  Rake::Task["bali:install:migrations"].enhance(["bali:install:migrations_notice"])
end
