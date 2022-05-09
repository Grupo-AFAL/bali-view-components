# frozen_string_literal: true

require_relative 'lib/bali/version'

Gem::Specification.new do |spec|
  spec.name        = 'bali_view_components'
  spec.version     = Bali::VERSION
  spec.authors     = ['Federico Gonzalez']
  spec.email       = ['fedegl@hey.com']
  spec.homepage    = 'https://github.com/Grupo-AFAL/bali'
  spec.summary     = 'View Components'
  spec.description = 'View Components'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.3')

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = 'allowed_push_host'

  spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = "TODO: Put your gem's public repo URL here."
  # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 7.0.2.3'

  spec.add_runtime_dependency 'view_component', ['>= 2.0.0', '< 3.0']
  spec.add_runtime_dependency 'view_component-contrib'

  spec.add_development_dependency 'rspec-rails'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
