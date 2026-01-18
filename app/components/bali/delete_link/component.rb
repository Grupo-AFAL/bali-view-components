# frozen_string_literal: true

module Bali
  module DeleteLink
    class Component < ApplicationViewComponent
      class MissingURL < StandardError; end

      SIZES = {
        xs: 'btn-xs',
        sm: 'btn-sm',
        md: '',
        lg: 'btn-lg'
      }.freeze

      BASE_CLASSES = 'btn btn-ghost text-error'

      attr_reader :options, :disabled_hover_url

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        model: nil,
        href: nil,
        name: nil,
        confirm: nil,
        size: nil,
        disabled: false,
        disabled_hover_url: nil,
        skip_confirm: false,
        icon: false,
        authorized: true,
        **options
      )
        @model = model
        @href = href
        @name = name
        @confirm = confirm
        @size = size&.to_sym
        @disabled = disabled
        @disabled_hover_url = disabled_hover_url
        @skip_confirm = skip_confirm
        @icon = icon
        @authorized = authorized
        @form_class = class_names('inline-block', options.delete(:form_class))
        @options = options

        validate_url_presence!
      end
      # rubocop:enable Metrics/ParameterLists

      def render?
        @authorized
      end

      def authorized?
        @authorized
      end

      def href
        @href || @model
      end

      def name
        @name.presence || content.presence || t('.default_name')
      end

      def confirm_message
        return if @skip_confirm

        @confirm.presence || default_confirm_message
      end

      def icon?
        @icon
      end

      def disabled?
        @disabled
      end

      def button_classes
        class_names(
          BASE_CLASSES,
          SIZES[@size],
          { 'btn-disabled' => @disabled },
          @options[:class]
        )
      end

      def form_classes
        @form_class
      end

      def button_options
        @options.except(:class)
      end

      private

      def default_confirm_message
        if @model.present?
          t('.specific_confirm_message', pronoun: pronoun, name: model_name)
        else
          t('.generic_confirm_message')
        end
      end

      def model_name
        @model.model_name.human
      end

      def pronoun
        t("activerecord.pronouns.#{@model.model_name.i18n_key}")
      end

      def validate_url_presence!
        return if @href.present? || @model.present?

        raise MissingURL, 'Provide either :model or :href'
      end
    end
  end
end
