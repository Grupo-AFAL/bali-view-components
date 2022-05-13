# frozen_string_literal: true

module ViewComponentCustom
  module Storybook
    module Sidecarable
      def self.extended(base)
        base.singleton_class.prepend(ClassMethods)
      end

      module ClassMethods
        # Override this methods defined on ViewComponent::Storybook::Stories since we are placing
        # the stories in the same Sidecar folder as the rest of the component files.
        def load_stories
          if stories_path
            Dir["#{stories_path}/**/stories.rb"].each do |file|
              require_dependency file
            end
          end
        end

        # Converts a story class (PageHeader::Stories) to a component class (PageHeader::Component)
        def default_component
          [name.chomp('Stories'), 'Component'].join.constantize
        end

        # Generates a name for the component. (page_header)
        def stories_name
          name.chomp('::Stories').underscore
        end

        # Stores JSON stories files within the component folder. Important that the json file
        # ends with .stories.json, otherwise Storybook doesn't seem to detect it.
        def write_csf_json
          json_path = File.join(stories_path, "#{stories_name}/_.stories.json")
          File.open(json_path, 'w') do |f|
            f.write(JSON.pretty_generate(to_csf_params))
          end
          json_path
        end
      end
    end
  end
end

ActiveSupport.on_load(:view_component) do
  # Extend your preview controller to support authentication and other
  # application-specific stuff
  #
  # Rails.application.config.to_prepare do
  #   ViewComponentsController.class_eval do
  #     include Authenticated
  #   end
  # end
  #
  # Make it possible to store previews in sidecar folders
  # See https://github.com/palkan/view_component-contrib#organizing-components-or-sidecar-pattern-extended
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
  # Enable `self.abstract_class = true` to exclude previews from the list
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract
end

ActiveSupport.on_load(:view_component_storybook) do
  ViewComponent::Storybook::Stories.extend ViewComponentCustom::Storybook::Sidecarable
end
