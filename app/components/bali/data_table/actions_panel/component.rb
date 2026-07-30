# frozen_string_literal: true

module Bali
  module DataTable
    module ActionsPanel
      class Component < ApplicationViewComponent
        include Bali::Utils::Url

        renders_many :actions, ->(method: :get, href: nil, **options) do
          Bali::DataTable::Action::Component.new(
            method: method, href: build_url(url: href), **options
          )
        end

        def initialize(filter_form:, url:)
          @filter_form = filter_form
          @url = url
        end

        def build_url(query_params = {}, url: nil)
          base_params = @filter_form ? { q: @filter_form.ransack_params } : {}
          add_query_params(url || @url, base_params.merge(query_params))
        end
      end
    end
  end
end
