# frozen_string_literal: true

module Bali
  module BpmnEditor
    class Preview < ApplicationViewComponentPreview
      # A read-only diagram: no `urls:` and no `editable:`. Three lanes, the
      # first an external participant (grey lane, white activities), a
      # message flow from it, a decision with labelled branches and an
      # annotation. Clicking a sub-process with a `reference.url` navigates.
      # @param locale select { choices: [es, en] }
      def default(locale: :es)
        island(locale, data: BpmnSampleFlows.invoice)
      end

      # The same flow with vertical lanes. Its nodes carry no coordinates, so
      # the island lays it out on load.
      # @param locale select { choices: [es, en] }
      def vertical(locale: :es)
        island(locale, data: BpmnSampleFlows.invoice(orientation: "vertical"))
      end

      # @label Large (60 activities)
      # Sixty activities and ten decisions over four lanes, laid out on load.
      def large
        island(:es, data: BpmnSampleFlows.large)
      end

      # An empty document still mounts the island and its empty canvas.
      def empty
        island(:es, data: { version: 1, lanes: [], nodes: [], edges: [] })
      end

      private

      def island(locale, **options)
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/component",
            locals: { component: Bali::BpmnEditor::Component.new(
              i18n: Bali::BpmnEditor::Translations.island(locale: locale), **options
            ) }
          )
        end
      end
    end
  end
end
