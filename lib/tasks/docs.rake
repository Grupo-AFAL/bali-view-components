# frozen_string_literal: true

namespace :docs do
  desc 'Generate YARD API documentation'
  task yard: :environment do
    puts 'Generating YARD documentation...'
    system('bundle exec yard doc')
    puts 'Documentation generated at spec/dummy/public/api-docs/index.html'
  end

  desc 'Start YARD documentation server'
  task server: :environment do
    puts 'Starting YARD server at http://localhost:8808'
    system('bundle exec yard server --reload')
  end

  desc 'Generate component catalog JSON for external documentation'
  task catalog: :environment do
    require 'json'

    components = Dir.glob('app/components/bali/*/component.rb').map do |file|
      component_name = file.match(%r{bali/(\w+)/component\.rb})[1]
      component_class = "Bali::#{component_name.camelize}::Component"

      begin
        klass = component_class.constantize

        {
          name: component_name,
          class_name: component_class,
          variants: klass.const_defined?(:VARIANTS) ? klass::VARIANTS.keys : [],
          sizes: klass.const_defined?(:SIZES) ? klass::SIZES.keys : [],
          has_slots: klass.respond_to?(:registered_slots) && klass.registered_slots.any?,
          file_path: file
        }
      rescue NameError => e
        puts "Warning: Could not load #{component_class}: #{e.message}"
        nil
      end
    end.compact

    catalog = {
      generated_at: Time.current.iso8601,
      component_count: components.size,
      components: components.sort_by { |c| c[:name] }
    }

    output_path = Rails.public_path.join('component-catalog.json')
    File.write(output_path, JSON.pretty_generate(catalog))
    puts "Component catalog generated at #{output_path}"
  end

  desc 'Generate all documentation (YARD + catalog)'
  task all: %i[yard catalog] do
    puts 'All documentation generated!'
  end
end
