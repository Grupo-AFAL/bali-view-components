# frozen_string_literal: true

module DemoWidgets
  # THE ABBREVIATION CASE. The real figure is 2,062,000,000 and a ~215px tile at
  # `text-4xl` fits four to six characters — so `formatted_value` overrides, and it
  # overrides rather than leaning on `abbreviate` alone because the headline is
  # money and dropping the currency would make it a different number.
  class ProductionBudget < Bali::Widget::ValueBase
    default_size :small

    def value = Movie.budgeted.sum(:budget).to_i

    def formatted_value = "$#{Bali::Widget.abbreviate(value)}"
  end
end
