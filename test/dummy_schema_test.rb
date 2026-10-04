# frozen_string_literal: true

require "test_helper"
require "open3"
require "tmpdir"

# `db:schema:load` reads the dummy's schema.rb and any `db:migrate` rewrites it, so the two have to
# agree or the first database someone migrates erases tables from the committed file. This migrates
# from test/dummy, the directory without `ENGINE_ROOT`, where Rails does not add the engine's
# migrations on its own.
#
# A subprocess, not an in-process migration: a migration writes through `ActiveRecord::Base`'s
# connection, so migrating another database here would swap out the one this test runs on.
class DummySchemaTest < ActiveSupport::TestCase
  test "migrating a database the server has already opened writes the committed schema.rb" do
    Dir.mktmpdir do |dir|
      database = File.join(dir, "fresh.sqlite3")
      dumped = File.join(dir, "schema.rb")
      # The server's pending check leaves `schema_migrations` created and empty on the first request.
      # Without that table `db:migrate` loads the file SCHEMA names, when it exists, instead of
      # migrating — and a test that loads schema.rb compares the file with itself.
      SQLite3::Database.open(database) do |db|
        db.execute('CREATE TABLE "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY)')
      end
      # CI sets COVERAGE, and SimpleCov's minimum fails a child that only ran migrations (0 / 1072).
      env = { "DATABASE_URL" => "sqlite3:#{database}", "SCHEMA" => dumped, "COVERAGE" => nil }

      output, status = Open3.capture2e(env, RbConfig.ruby, "bin/rails", "db:migrate", chdir: Rails.root.to_s)

      assert status.success?, output
      assert_equal Rails.root.join("db/schema.rb").read, File.read(dumped)
    end
  end
end
