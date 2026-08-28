# frozen_string_literal: true

module Bali
  module Testing
    # THE ONE COST OF WRITING THE CATALOG BY HAND: a widget class you added and
    # forgot to list is on no dashboard, renders nowhere, and nothing says so.
    # It is not a crash — it is a feature that quietly does not exist.
    #
    # This is the check, not a replacement. Bali does not discover widgets,
    # because a catalog's ORDER is the dashboard's default layout and discovery
    # can only ever give you alphabetical. So the list stays yours to author;
    # this just refuses to let you forget an entry.
    #
    #   require "bali/testing/widget_catalog"
    #
    #   class WidgetCatalogTest < ActiveSupport::TestCase
    #     include Bali::Testing::WidgetCatalog
    #
    #     def test_every_widget_is_on_a_dashboard
    #       assert_every_widget_catalogued DashboardController, SalesDashboardController
    #     end
    #   end
    #
    # TEST-ONLY, and required explicitly rather than from `lib/bali.rb`: it
    # globs the filesystem and constantizes what it finds, which is fine in a
    # test run and has no business happening at boot.
    module WidgetCatalog
      # Each argument is either a controller that `include`s
      # `Bali::Concerns::Controllers::DashboardWidgets`, or a bare array of
      # widget classes for a host that keeps its catalogs somewhere else.
      def assert_every_widget_catalogued(*catalogs, path: "app/widgets")
        listed  = catalogs.flat_map { |catalog| bali_catalog_classes(catalog) }.uniq
        missing = bali_widget_classes_under(path) - listed

        assert_empty missing,
                     "#{missing.map(&:name).join(', ')} " \
                     "#{missing.one? ? 'is a widget that is' : 'are widgets that are'} on no dashboard. " \
                     "Add #{missing.one? ? 'it' : 'them'} to a `dashboard_widgets catalog:` — position in " \
                     "that list is where the card appears for someone who has never rearranged."
      end

      private

      def bali_catalog_classes(catalog)
        return Array(catalog) unless catalog.respond_to?(:widget_catalog)

        declared = catalog.widget_catalog
        # A lazy catalog is a controller-instance expression; there is nothing to
        # read statically. Say so rather than silently checking against nothing.
        if declared.is_a?(Proc) || declared.is_a?(Symbol)
          raise ArgumentError,
                "#{catalog.name}'s catalog is #{declared.inspect}, which is resolved per request and " \
                "cannot be read here. Pass the widget classes directly instead."
        end

        Array(declared)
      end

      # FROM THE FILESYSTEM, not `Base.descendants`. Descendants sweeps up every
      # anonymous widget a test suite has ever defined — including this suite's
      # own fixtures — and reports them as uncatalogued. A file under the host's
      # widget directory is exactly the set a developer means by "my widgets".
      def bali_widget_classes_under(path)
        root = Rails.root.join(path)

        Dir[root.join("**/*.rb")].sort.filter_map do |file|
          constant = file.delete_prefix("#{root}/").delete_suffix(".rb").camelize.safe_constantize

          constant if constant.is_a?(Class) && constant < Bali::Widget::Base
        end
      end
    end
  end
end
