# frozen_string_literal: true

module Bali
  module DeleteLink
    class Component < ApplicationViewComponent
      class MissingURL < StandardError; end

      attr_reader :model, :skip_confirm
  
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        model: nil, 
        href: nil, 
        name: nil,
        confirm: nil,
        classes: nil,
        disabled: false,
        disabled_hover_url: nil,
        skip_confirm: false
      )
        @model = model
        @href = href
        @name = name
        @confirm = confirm
        @classes = classes
        @disabled = disabled
        @disabled_hover_url = disabled_hover_url
        @skip_confirm = skip_confirm
  
        return unless @href.blank? && @model.blank?
  
        raise MissingURL, 'Need to provide either a :model or :href attribute'
      end
      # rubocop:enable Metrics/ParameterLists

  
      def href
        @href || @model
      end
  
      def name
        return @name if @name.present?
  
        if model.present?
          t('.specific_name', **translation_attributes)
        else
          t('.generic_name')
        end
      end
  
      def confirm
        return if skip_confirm
        return @confirm if @confirm.present?
  
        if model.present?
          t('.specific_confirm_message', **translation_attributes)
        else
          t('.generic_confirm_message')
        end
      end
  
      def classes
        class_names('has-text-danger', @classes)
      end
  
      private
  
      def translation_attributes
        { pronoun: pronoun, name: model_name }
      end
  
      def model_name
        model.model_name.human
      end
  
      def pronoun
        t("activerecord.pronouns.#{model.model_name.i18n_key}")
      end
    end
  end
end