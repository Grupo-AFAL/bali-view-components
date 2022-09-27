# frozen_string_literal: true

require 'date'

class LibraryVersion < Thor
  include Thor::Actions

  desc 'bump', 'updates version.rb, package.json and appends to changelog'
  method_option :number, aliases: '-n', desc: 'New version number'
  def bump(number)
    gsub_file '../lib/bali/version.rb', /VERSION = '(\d{1,2}.\d{1,2}.\d{1,2})'/,
              "VERSION = '#{number}'"
    gsub_file '../package.json', /"version": "(\d{1,2}.\d{1,2}.\d{1,2})"/,
              "\"version\": \"#{number}\""

    insert_into_file '../CHANGELOG.md', changelog_placeholder(number), after: changelog_target_text
    run 'bundle install'
  end

  private

  # rubocop:disable Rails/Date
  def changelog_placeholder(number)
    "\n\n## [#{number}] - #{Date.today}\n" \
      "\n" \
      "### Added|Changed|Removed|Fixed|Security\n" \
      '- Describe changes'
  end
  # rubocop:enable Rails/Date

  def changelog_target_text
    'and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).'
  end
end
