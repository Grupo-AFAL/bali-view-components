# frozen_string_literal: true

module DemoWidgets
  # THE ABBREVIATION RUNG. A ~215px tile at `text-4xl` has room for four to six
  # characters, and the real figure here is 2,062,000,000 — so this is the widget
  # that shows why `display_value` exists.
  #
  # It overrides rather than leaning on `Bali::Widget.abbreviate`, because the
  # headline is money: `abbreviate` would render "2.1B" and drop the currency,
  # which is a different number.
  class ProductionBudget < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :small

    def call
      Bali::Widget::Result.new(
        count: total.to_i,
        display_value: "$#{Bali::Widget.abbreviate(total)}",
        view_all_path: admin_movies_path
      )
    end

    private

    def total
      @total ||= Movie.budgeted.sum(:budget)
    end
  end
end
