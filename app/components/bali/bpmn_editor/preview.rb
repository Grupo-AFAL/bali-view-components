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

      # @label Editable (dummy endpoints)
      # The complete editor against the dummy's reference endpoints
      # (Admin::ProcessFlows::DiagramsController / FinalizationsController):
      # every change autosaves the whole document with its version, a stale
      # version answers 409 and the island reloads. Requires the seeded flow
      # (`bin/rails db:seed`); edits PERSIST in the dummy database.
      # `fresh` (on by default) puts the flow back to the sample first, so the
      # preview always starts from the same clean document; switch it off to
      # see your saved edits after a reload.
      # @param autosave toggle
      # @param fresh toggle
      # @param palette select { choices: [descriptive, analytic, full] }
      def editable(autosave: true, fresh: true, palette: :analytic)
        flow = fresh ? ProcessFlow.reset_sample! : ProcessFlow.order(:id).first
        I18n.with_locale(:es) do
          render_with_template(
            template: "bali/bpmn_editor/previews/editable",
            locals: { flow: flow, autosave: autosave, palette: palette.to_sym }
          )
        end
      end

      # @label Palette and legend configured by the host
      # The full palette with one item disabled and three marked with a note
      # (dotted outline, the note in the tooltip, the note legend at the foot of
      # the palette), and a legend with one entry removed and one added.
      def configured
        flow = ProcessFlow.order(:id).first
        I18n.with_locale(:es) do
          render_with_template(
            template: "bali/bpmn_editor/previews/configured",
            locals: { flow: flow }
          )
        end
      end

      # @label Review notes and comparison (read-only)
      # A viewer with numbered review notes (tags and colours from the host) and
      # a previous version to compare against: "Compare" shows what was
      # added, removed and changed, over one canvas or side by side. The
      # image, SVG and print outputs carry the "Borrador" watermark.
      def review
        current = BpmnSampleFlows.invoice
        current[:nodes] = current[:nodes].map { |n| n[:id] == "t4" ? n.merge(name: "Programar transferencia bancaria") : n }
        current[:nodes] << { id: "t5", type: "send_task", lane_id: "l2", name: "Notificar al proveedor", x: 960, y: 290 }
        current[:annotations] = [
          { id: "a1", target_id: "t1", number: 1, text: "¿Quién valida las facturas en el extranjero?", tag: "question" },
          { id: "a2", target_id: "t4", number: 2, text: "Se automatiza en el segundo trimestre.", tag: "keep" }
        ]
        previous = BpmnSampleFlows.invoice
        previous[:nodes] << { id: "t0", type: "task", lane_id: "l2", name: "Imprimir factura", x: 700, y: 300 }
        island(:es, data: current, name: "Pago a proveedores", watermark: "Borrador",
                    annotation_tags: [ { key: "question", label: "Pregunta", color: "#2563eb" },
                                       { key: "keep", label: "Mantener", color: "#16a34a" } ],
                    compare_with: { document: previous, label: "Vigente v1.0" })
      end

      # @label Large (60 activities)
      # Sixty activities and ten decisions over four lanes, laid out on load.
      def large
        island(:es, data: BpmnSampleFlows.large)
      end

      # @label Catalog of shapes
      # Every element of the palette, one row per group: on the left as its
      # palette icon draws it (28 px), on the right as the canvas does, with
      # its palette name. The two come from one drawing (shapes.jsx).
      def catalog
        island(:es, data: BpmnSampleFlows.catalog(Bali::BpmnEditor::Translations.island(locale: :es)))
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
