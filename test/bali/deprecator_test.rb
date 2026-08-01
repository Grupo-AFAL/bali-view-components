# frozen_string_literal: true

require "test_helper"

class BaliDeprecatorTest < ActiveSupport::TestCase
  def test_deprecator_announces_the_gem_and_its_removal_horizon
    assert_instance_of(ActiveSupport::Deprecation, Bali.deprecator)
    assert_equal("4.0", Bali.deprecator.deprecation_horizon)
    assert_equal("Bali", Bali.deprecator.gem_name)
  end

  # Registered so a host configures Bali's warnings with the same
  # config.active_support.deprecation it already uses for Rails' own.
  def test_deprecator_is_registered_with_the_host_application
    assert_same(Bali.deprecator, Rails.application.deprecators[:bali])
  end

  def test_simple_filter_warns_through_the_bali_deprecator
    message = capture_warning do
      Class.new(Bali::FilterForm) do
        simple_filter :status, collection: [ %w[Done done] ], blank: "All"
      end
    end

    assert_match(/simple_filter is deprecated/, message)
    assert_match(/filter_attribute :status/, message)
  end

  # The deprecated DSL keeps producing the same definition it always did —
  # hosts get a warning, not a behaviour change.
  def test_simple_filter_still_declares_the_filter
    form_class = Bali.deprecator.silence do
      Class.new(Bali::FilterForm) do
        simple_filter :status, collection: [ %w[Done done] ], blank: "All", type: :slim_select
      end
    end

    definition = form_class.defined_simple_filters.sole
    assert_equal(:status, definition[:attribute])
    assert_equal([ %w[Done done] ], definition[:collection])
    assert_equal("All", definition[:blank])
    assert_equal(:slim_select, definition[:type])
    assert_equal([], form_class.new(Movie.all, ActionController::Parameters.new).available_attributes)
  end

  # Los dos componentes que #684 deja atrás. Ninguno se borra en v3: el aviso sale al
  # construirlos y el render sigue siendo el de siempre.
  def test_level_and_info_level_warn_through_the_bali_deprecator
    level = capture_warning { Bali::Level::Component.new }
    assert_match(/Bali::Level::Component is deprecated/, level)
    assert_match(/Bali::PageHeader::Component/, level)

    info_level = capture_warning { Bali::InfoLevel::Component.new }
    assert_match(/Bali::InfoLevel::Component is deprecated/, info_level)
    assert_match(/Bali::StatCard::Component/, info_level)
  end

  # PageHeader todavía se apoya en Level por dentro. Si el aviso saliera de ahí, un host que
  # nunca escribió `Bali::Level` recibiría una deprecación por cada encabezado de página —
  # ruido que no puede accionar.
  def test_page_header_does_not_leak_the_level_deprecation_to_the_host
    warnings = capture_warning do
      ApplicationController.render(
        Bali::PageHeader::Component.new(title: "Movies"), layout: false
      )
    end

    assert_empty(warnings)
  end

  private

  def capture_warning(&block)
    captured = []
    Bali.deprecator.behavior = ->(message, *) { captured << message }
    block.call
    captured.join("\n")
  ensure
    Bali.deprecator.behavior = :stderr
  end
end
