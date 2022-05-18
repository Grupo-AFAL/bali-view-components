# frozen_string_literal: true

module Bali
  module Table
    class Component < ApplicationViewComponent
      renders_many :headers, ->(name: nil, sort: nil, **options) do
        Header::Component.new(form: @form, name: name, sort: sort, **options)
      end

      renders_many :rows, Row::Component

      renders_many :footers, Footer::Component

      # TODO: Enable after a link component has been migrated/created
      # renders_one :new_record_link, ->(name:, href:, modal: true, **options) do
      #   Link::Component.new(name: name, href: href, type: :success, modal: modal, **options)
      # end

      attr_reader :form, :options, :tbody_options

      def initialize(form: nil, **options)
        @form = form
        @tbody_options = hyphenize_keys((options.delete(:tbody) || {}))
        @options = prepend_class_name(hyphenize_keys(options), 'table is-fullwidth')
      end

      def id
        @options['id'] || form&.id
      end

      class MissingFilterForm < StandardError; end
    end
  end
end
