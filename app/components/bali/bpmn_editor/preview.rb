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
      # see your saved edits after a reload. `external_lanes` off hides the
      # lane panel's "external participant" checkbox and its legend entries.
      # @param locale select { choices: [es, en] }
      # @param autosave toggle
      # @param fresh toggle
      # @param external_lanes toggle
      # @param palette select { choices: [descriptive, analytic, full] }
      def editable(locale: :es, autosave: true, fresh: true, external_lanes: true, palette: :analytic)
        flow = fresh ? ProcessFlow.reset_sample! : ProcessFlow.order(:id).first
        render_with_template(
          template: "bali/bpmn_editor/previews/editable",
          locals: { flow: flow, locale: locale, autosave: autosave, external_lanes: external_lanes, palette: palette.to_sym }
        )
      end

      # @label Palette and legend configured by the host
      # The full palette with one item disabled and three marked with a note
      # (dotted outline, the note in the tooltip, the note legend at the foot of
      # the palette), and a legend with one entry removed and one added.
      # @param locale select { choices: [es, en] }
      def configured(locale: :es)
        flow = ProcessFlow.order(:id).first
        render_with_template(template: "bali/bpmn_editor/previews/configured", locals: { flow: flow, locale: locale })
      end

      # @label Review notes and comparison (read-only)
      # A viewer with numbered review notes (tags and colours from the host) and
      # a previous version to compare against: "Compare" shows what was
      # added, removed and changed, over one canvas or side by side. The
      # image, SVG and print outputs carry the "Borrador" watermark.
      # @param locale select { choices: [es, en] }
      def review(locale: :es)
        current = BpmnSampleFlows.invoice
        current[:nodes] = current[:nodes].map { |n| n[:id] == "t4" ? n.merge(name: "Programar transferencia bancaria") : n }
        current[:nodes] << { id: "t5", type: "send_task", lane_id: "l2", name: "Notificar al proveedor", x: 960, y: 290 }
        current[:annotations] = [
          { id: "a1", target_id: "t1", number: 1, text: "¿Quién valida las facturas en el extranjero?", tag: "question" },
          { id: "a2", target_id: "t4", number: 2, text: "Se automatiza en el segundo trimestre.", tag: "keep" }
        ]
        previous = BpmnSampleFlows.invoice
        previous[:nodes] << { id: "t0", type: "task", lane_id: "l2", name: "Imprimir factura", x: 700, y: 300 }
        island(locale, data: current, name: "Pago a proveedores", watermark: "Borrador",
                       review: {
                         tags: [ { key: "question", label: "Pregunta", color: "#2563eb" },
                                 { key: "keep", label: "Mantener", color: "#16a34a" } ],
                         compare_with: { document: previous, label: "Vigente v1.0" }
                       })
      end

      # @label Large (60 activities)
      # Sixty activities and ten decisions over four lanes, laid out on load.
      # @param locale select { choices: [es, en] }
      def large(locale: :es)
        island(locale, data: BpmnSampleFlows.large)
      end

      # @label Catalog of shapes
      # Every element of the palette, one row per group: on the left as its
      # palette icon draws it (28 px), on the right as the canvas does, with
      # its palette name. The two come from one drawing (shapes.jsx).
      # @param locale select { choices: [es, en] }
      def catalog(locale: :es)
        island(locale, data: BpmnSampleFlows.catalog(Bali::BpmnEditor::Translations.island(locale: locale)))
      end

      # An empty document still mounts the island and its empty canvas.
      # @param locale select { choices: [es, en] }
      # @label Two editors on one page
      # Two editors of the same flow: an event a host sends to one (a linked
      # sub-process, a reload) reaches that one only.
      # @param locale select { choices: [es, en] }
      def pair(locale: :es)
        data = BpmnSampleFlows.invoice
        data[:nodes] << { id: "sp", type: "sub_process", lane_id: "l3", name: "Procedimiento", x: 1150, y: 388 }
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/pair",
            locals: { first: Bali::BpmnEditor::Component.new(data: data, id: "first_bpmn"),
                      second: Bali::BpmnEditor::Component.new(data: data, id: "second_bpmn") }
          )
        end
      end

      def empty(locale: :es)
        island(locale, data: { version: 1, lanes: [], nodes: [], edges: [] })
      end

      # @label Rules gallery
      # One modelling rule at a time: a small flow that breaks it (`failing`) or
      # one that does not (`passing`), with the pending-issues panel open. Pick a
      # rule and compare both; open «Reglas» to see every rule and its state. The
      # rules marked as optional only run when the optional rule package is on —
      # in a host, that is importing `bali-view-components/bpmn-editor/afal-rules`
      # in the island's entry (here, a second island bundle loaded only by this
      # preview). Rules and their options: docs/api/bpmn-editor.md#rules
      # @param rule select :gallery_rules
      # @param example select { choices: [failing, passing] }
      # @param optional_rules toggle "Load the optional rule package"
      # @param locale select { choices: [es, en] }
      def rules_gallery(rule: "R01", example: "failing", optional_rules: false, locale: :es)
        rule = rule.to_s
        optional = BpmnRuleExamples.optional_rule_ids.include?(rule)
        sample = BpmnRuleExamples.example(rule, example)
        flow = ProcessFlow.find_or_initialize_by(name: "Rules gallery")
        flow.update!(document: sample[:document], version: 1, finalized_at: nil)
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/rules_gallery",
            locals: { flow: flow, rule: rule, example: example.to_s, optional: optional,
                      optional_rules: optional_rules, sample: sample }
          )
        end
      end

      private

      # The rules the gallery has an example for: every rule of the editor and
      # of the optional rule package (test/fixtures/bpmn_editor/rule_examples.json).
      def gallery_rules
        BpmnRuleExamples.rule_ids
      end

      # The island's strings follow the locale the component is built in
      # (Component#island_i18n), so none are passed.
      def island(locale, **options)
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/component",
            locals: { component: Bali::BpmnEditor::Component.new(**options) }
          )
        end
      end
    end
  end
end
