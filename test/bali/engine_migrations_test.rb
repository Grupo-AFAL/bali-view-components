# frozen_string_literal: true

require "test_helper"
require "rake"
require "bali/engine_migrations"

# The narrow half of `bali:install:migrations` (#1079): the umbrella task copies every
# migration the engine ships, these copy one feature's.
class BaliEngineMigrationsTest < ActiveSupport::TestCase
  RAKE_FILE = Bali::Engine.root.join("lib/tasks/bali_tasks.rake")

  def test_every_shipped_migration_is_a_feature
    shipped = Dir[Bali::Engine.root.join("db/migrate/*.rb").to_s]

    assert_not_empty shipped
    assert_equal shipped.sort, Bali::EngineMigrations.all.values.sort
  end

  # The feature name is what a host types after the colon, so it carries neither the
  # timestamp nor the `create_bali_` prefix.
  def test_feature_names_are_the_bare_feature
    assert_includes Bali::EngineMigrations.all.keys, "saved_views"
    Bali::EngineMigrations.all.each do |feature, path|
      assert_match(/\A[a-z_]+\z/, feature)
      assert_equal feature, File.basename(path, ".rb").sub(/\A\d+_create_bali_/, "")
    end
  end

  def test_path_for_rejects_an_unknown_feature
    error = assert_raises(Bali::EngineMigrations::UnknownFeature) do
      Bali::EngineMigrations.path_for(:sabed_views)
    end

    assert_match "saved_views", error.message
  end

  def test_install_copies_only_the_feature_asked_for
    in_destination do |destination|
      Bali::EngineMigrations.install("saved_views", destination: destination)

      copied = Dir.children(destination)
      assert_equal 1, copied.size, "copied #{copied.inspect}"
      assert_match(/\A\d+_create_bali_saved_views\.bali\.rb\z/, copied.first)
    end
  end

  # Rails' copier renumbers to the moment of the copy and refuses a migration whose name
  # the app already has. Both come along with #install narrowing the source rather than
  # reimplementing the copy — which is the point of installing a feature at a time being
  # safe to repeat as an app adopts the next one.
  def test_install_renumbers_and_leaves_what_is_already_installed_alone
    in_destination do |destination|
      Bali::EngineMigrations.install("saved_views", destination: destination)
      saved_views = Dir.children(destination).first

      Bali::EngineMigrations.install("acknowledgments", destination: destination)
      Bali::EngineMigrations.install("saved_views", destination: destination)

      assert_equal 2, Dir.children(destination).size
      assert_includes Dir.children(destination), saved_views
      assert_operator saved_views[/\A\d+/].to_i, :>, 20260806150000,
                      "#{saved_views} kept the version it has inside the gem"
    end
  end

  # The tasks are generated from .all, so what is worth proving here is that the file
  # loads at all — nothing else in the suite ever reads it.
  def test_the_rake_file_defines_one_task_per_feature
    names = in_a_fresh_rake_application { |app| app.tasks.map(&:name) }

    Bali::EngineMigrations.all.each_key do |feature|
      assert_includes names, "bali:install:migrations:#{feature}"
    end
  end

  private

  def in_destination
    Dir.mktmpdir("bali-install-migrations-test") do |destination|
      yield File.join(destination, "migrate")
    end
  end

  def in_a_fresh_rake_application
    previous = Rake.application
    Rake.application = Rake::Application.new
    load RAKE_FILE
    yield Rake.application
  ensure
    Rake.application = previous
  end
end
