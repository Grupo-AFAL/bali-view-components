# frozen_string_literal: true

require 'date'
require 'active_support'

class LibraryVersion < Thor
  include Thor::Actions

  desc 'bump', 'updates version.rb, package.json and appends to changelog'
  method_option :number, aliases: '-n', desc: 'New version number'
  method_option :version_type, aliases: '-v', desc: 'Bump version type (major, minor, patch)'
  def bump
    new_number = options[:number] || generate_new_version_number

    gsub_file '../lib/bali/version.rb', /VERSION = '(\d{1,3}.\d{1,3}.\d{1,3})'/,
              "VERSION = '#{new_number}'"
    gsub_file '../package.json', /"version": "(\d{1,3}.\d{1,3}.\d{1,3})"/,
              "\"version\": \"#{new_number}\""

    insert_into_file '../CHANGELOG.md', changelog_placeholder(new_number),
                     after: changelog_target_text
  end

  def self.exit_on_failure?
    true
  end

  private

  def generate_new_version_number
    major, minor, patch = current_version_number

    case options[:version_type]
    when 'major'
      major += 1
      minor = 0
      patch = 0
    when 'minor'
      minor += 1
      patch = 0
    when 'patch'
      patch += 1
    else
      raise Thor::Error,
            'Invalid version type, please provide either -n VERSION_NUMBER or -v major|minor|patch'
    end

    "#{major}.#{minor}.#{patch}"
  end

  def current_version_number
    version_rb = File.binread('../lib/bali/version.rb')
    match = version_rb.match(/VERSION = '(\d{1,3}.\d{1,3}.\d{1,3})'/)
    match[1].split('.').map(&:to_i)
  end

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
