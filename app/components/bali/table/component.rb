# frozen_string_literal: true

module Bali
  module Table
    class Component < ApplicationViewComponent
      renders_many :headers, ->(name: nil, sort: nil, **options) do
        Header::Component.new(form: @form, name: name, sort: sort, **options)
      end

      renders_many :rows, Row::Component

      renders_many :footers, Footer::Component

      renders_one :new_record_link, ->(name:, href:, modal: true, **options) do
        Link::Component.new(name: name, href: href, type: :success, modal: modal, **options)
      end

      attr_reader :form, :options, :tbody_options

      def initialize(form: nil, **options)
        @form = form
        @class = options.delete(:class)
        @tbody_options = (options.delete(:tbody) || {}).transform_keys { |k| k.to_s.gsub('_', '-') }
        @options = options.transform_keys { |k| k.to_s.gsub('_', '-') }
      end

      def table_container_classes
        class_names('table-container table-component')
      end

      def table_classes
        class_names('table is-fullwidth', @class)
      end

      def id
        @options['id'] || form&.id
      end

      class MissingFilterForm < StandardError; end
    end
  end
end
