# frozen_string_literal: true

namespace :storybook do
  desc 'Rebuild storybook assets'
  task rebuild: :environment do
    Rake::Task['view_component_storybook:write_stories_json'].invoke
    sh 'yarn storybook:build'
  end
end
