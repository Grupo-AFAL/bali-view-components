# frozen_string_literal: true

require "tmpdir"
require "fileutils"

module Bali
  # The migrations the engine ships, one per feature, and how to install just ONE of them.
  #
  # Rails' own `bali:install:migrations` copies every migration an engine ships. Bali ships
  # five and they are unrelated to each other — an app that adopts saved views also gets
  # content versions, entity references, acknowledgments and block editor comments, four
  # tables it never asked for in the `db/schema.rb` every one of its PRs reviews (#1079).
  # The guide's per-feature sections all pointed at that one command, so following the
  # recipe literally was the way to hit it.
  #
  # `bali:install:migrations:<feature>` is the narrow spelling. Everything about the copy
  # stays Rails' — see #install.
  module EngineMigrations
    class UnknownFeature < ArgumentError; end

    # The prefix every engine migration's name starts with. What follows it is the feature.
    FEATURE_PREFIX = /\A\d+_create_bali_/

    class << self
      # feature name => absolute path of the migration that installs it. Derived from the
      # file names rather than declared, so a new engine migration gets its task without a
      # second list to keep in sync.
      def all
        @all ||= Dir[Engine.root.join("db", "migrate", "*.rb").to_s].sort.to_h do |path|
          [ File.basename(path, ".rb").sub(FEATURE_PREFIX, ""), path ]
        end
      end

      def path_for(feature)
        all.fetch(feature.to_s) do
          raise UnknownFeature, "Unknown Bali migration #{feature.inspect}. " \
                                "Known features: #{all.keys.join(", ")}"
        end
      end

      # Copies one feature's migration into `destination`, through the very copier Rails'
      # own task uses — over a directory holding just that file. Narrowing what is offered
      # to the copier, rather than reimplementing it, is what keeps the renumbering, the
      # `.bali.rb` scope suffix and the already-installed check identical to installing all
      # five.
      def install(feature, destination:, on_skip: nil, on_copy: nil)
        source = path_for(feature)

        Dir.mktmpdir("bali-migrations") do |dir|
          FileUtils.cp(source, dir)
          ActiveRecord::Migration.copy(destination, { bali: dir },
                                       on_skip: on_skip, on_copy: on_copy)
        end
      end

      # Where the app keeps its migrations, resolved the same way Rails' own
      # `railties:install:migrations` resolves it, `DATABASE=` included.
      def destination_for(database = nil)
        return ActiveRecord::Tasks::DatabaseTasks.migrations_paths.first if
          database.blank? || database == "primary"

        config = ActiveRecord::Base.configurations.configs_for(name: database)
        raise ArgumentError, "Invalid DATABASE provided" if config.blank?

        paths = config.migrations_paths
        raise ArgumentError, "#{database} does not have a custom migration path" if paths.blank?

        Array(paths).first
      end
    end
  end
end
