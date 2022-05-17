# frozen_string_literal: true

module Bali
  module Table
    module Header
      class Component < ApplicationViewComponent
        def initialize(name: nil, form: nil, sort: nil, **options)
          @name = name
          @form = form
          @sort_attribute = sort
          @options = options.transform_keys { |k| k.to_s.gsub('_', '-') }
        end

        def call
          if @sort_attribute.present? && @form.blank?
            raise MissingFilterForm, 'FilterForm is required for sorting'
          end

          if @sort_attribute.present? && @form.present?
            opened = helpers.params.delete('opened')
            @name = helpers.sort_link(@form.ransack_search, @sort_attribute, @name)
            helpers.params['opened'] = opened
          end

          tag.th(@name, **@options)
        end
      end
    end
  end
end
