# frozen_string_literal: true

module Bali
  module BpmnEditor
    class Preview < ApplicationViewComponentPreview
      # The sheets the playground offers, in inches.
      PAGES = {
        "letter_landscape" => { width: 8.5, height: 11, orientation: "landscape" },
        "letter_portrait" => { width: 8.5, height: 11, orientation: "portrait" },
        "a4_landscape" => { width: 8.27, height: 11.69, orientation: "landscape" },
        "a4_portrait" => { width: 8.27, height: 11.69, orientation: "portrait" },
        "legal_landscape" => { width: 8.5, height: 14, orientation: "landscape" },
        "legal_portrait" => { width: 8.5, height: 14, orientation: "portrait" }
      }.freeze

      # `rules:` presets: the defaults; strict (optional rules on, two warnings
      # raised to errors, a custom message, tighter limits); relaxed (three rules
      # off, a warning instead of an error, one lane allowed).
      RULE_PRESETS = {
        "default" => {},
        "strict" => {
          enabled: %w[R04 R14 R15 R17 R19 R20 B07],
          severities: { R11: :error, B11: :error },
          messages: { R07: "Name the outcome the flow ends with, e.g. «Invoice paid»." },
          options: { min_activities: 3, max_activities: 12 }
        },
        "relaxed" => {
          disabled: %w[R07 R09 R22],
          severities: { R08: :warning },
          options: { min_lanes: 1 }
        }
      }.freeze

      DOCS = "docs/api/bpmn-editor.md"

      # @label Playground
      # The whole editor against the dummy app's endpoints
      # (Admin::ProcessFlows::*), every option a parameter. Each `sample` keeps
      # its own record per locale, and `fresh` (on) puts it back on every visit;
      # turn it off to find your edits after a reload.
      #
      # What to try: the quick menu next to a selected element (a second way
      # out of an activity offers a split), dragging from the palette onto a
      # connection, «Autoajustar», undo, the properties panel, «Reglas» and the
      # pending panel, «Finalizar», the outputs (PNG, SVG, print, .bpmn) and
      # «Importar». `server` makes the dummy answer like a host in trouble —
      # demonstration only (Admin::ProcessFlows::DemoServer). Every option:
      # docs/api/bpmn-editor.md
      # @param sample select "The flow to start from" { choices: [invoice, empty, rework, parallel, partners, large] }
      # @param orientation select "Lanes stacked vertically (horizontal) or side by side (vertical)" { choices: [horizontal, vertical] }
      # @param palette select "Palette preset" { choices: [descriptive, analytic, full] }
      # @param layout select "What «Autoajustar» and the first layout do" { choices: [compact, straight] }
      # @param page select "Sheet for the compact layout and the outputs" { choices: [letter_landscape, letter_portrait, a4_landscape, a4_portrait, legal_landscape, legal_portrait] }
      # @param lock_orientation toggle "Hide the orientation switch"
      # @param external_lanes toggle "Offer the external participant checkbox"
      # @param autosave toggle "Save after every change (off: only «Guardar borrador»)"
      # @param optional_rules toggle "Load the optional rule package"
      # @param rule_severity select "Rule configuration: default, strict or relaxed" { choices: [default, strict, relaxed] }
      # @param server select "How the dummy server answers (demonstration only)" { choices: [normal, conflict, error, slow, issues, reject_finalize] }
      # @param theme select "Page theme" { choices: [light, dark] }
      # @param locale select { choices: [es, en] }
      # @param name text "Title of the outputs and file name"
      # @param watermark text "Text across the outputs"
      # @param fresh toggle "Start from the sample on every visit"
      def playground(sample: "invoice", orientation: "horizontal", palette: :analytic, layout: :compact,
                     page: "letter_landscape", lock_orientation: false, external_lanes: true, autosave: true,
                     optional_rules: false, rule_severity: "default", server: "normal", theme: "light",
                     locale: :es, name: "", watermark: "", fresh: true)
        flow = ProcessFlow.for_sample(sample.to_s, locale: locale, fresh: fresh, orientation: orientation.to_s)
        render_with_template(
          template: "bali/bpmn_editor/previews/playground",
          locals: { flow: flow, locale: locale, theme: theme.to_s, optional_rules: optional_rules, server: server.to_s,
                    options: { palette: palette.to_sym, layout: layout.to_sym, page: PAGES.fetch(page.to_s),
                               lock_orientation: lock_orientation, external_lanes: external_lanes,
                               autosave: autosave, rules: RULE_PRESETS.fetch(rule_severity.to_s),
                               name: name.presence, watermark: watermark.presence } }
        )
      end

      # @label Read-only viewer
      # No `editable:` and no `urls:`: a diagram to look at. Three lanes, the
      # first an external participant (grey lane, white activities), a message
      # flow, a decision with labelled answers and an annotation. Try zooming,
      # «Pantalla completa», the outputs, and clicking a sub-process with a link.
      # docs/api/bpmn-editor.md
      # @param locale select { choices: [es, en] }
      def default(locale: :es)
        island(locale, data: BpmnSampleFlows.invoice(locale: locale))
      end

      # @label Host integration
      # What the app around the editor does: a console of the `bali-bpmn:*`
      # events the editors send (dirty-change, saved, finalized, open-reference,
      # with their detail), buttons that answer through the Turbo Stream helpers
      # (`bali_bpmn_reload`, `bali_bpmn_reference_created`) against one editor's
      # id, the read-only pattern (an alert the app composes above a locked
      # editor) and two flows in tabs whose label marks unsaved changes from
      # `bali-bpmn:dirty-change`. The console and the tabs' mark are the dummy's
      # own Stimulus controller, not the component's.
      # docs/api/bpmn-editor.md#extension-points
      # @param locale select { choices: [es, en] }
      def host_integration(locale: :es)
        invoice = BpmnSampleFlows.invoice(locale: locale)
        invoice[:nodes] << { id: "sp", type: "sub_process", lane_id: "l3", name: locale.to_s == "en" ? "Procedure" : "Procedimiento" }
        first = ProcessFlow.reset!("Host integration A (#{locale})", invoice)
        second = ProcessFlow.for_sample("rework", locale: locale, fresh: true, name: "Host integration B (#{locale})")
        locked = BpmnSampleFlows.sample("parallel", locale: locale)
        render_with_template(template: "bali/bpmn_editor/previews/host_integration",
                             locals: { first: first, second: second, locked: locked, locale: locale })
      end

      # @label Palette and legend configured by the app
      # The full palette with one item disabled and three marked with a note
      # (dotted outline, the note in the tooltip, the note legend at the foot of
      # the palette), and a legend with one entry removed and one added. Its
      # own record, back to the sample on every visit.
      # docs/api/bpmn-editor.md#palette
      # @param locale select { choices: [es, en] }
      def configured(locale: :es)
        flow = ProcessFlow.for_sample("invoice", locale: locale, fresh: true, name: "Configured (#{locale})")
        render_with_template(template: "bali/bpmn_editor/previews/configured", locals: { flow: flow, locale: locale })
      end

      # @label Review notes and comparison
      # Numbered review notes (tags and colours from the app) and a previous
      # version to compare against: «Comparar» shows what was added, removed
      # and changed, over one canvas or side by side. The outputs carry the
      # watermark. With `editable` on, select an element and add notes in the
      # properties panel; they are saved to this preview's own record.
      # docs/api/bpmn-editor.md#outputs-notes-and-comparison
      # @param editable toggle "Let notes be added and edited"
      # @param locale select { choices: [es, en] }
      def review(editable: false, locale: :es)
        en = locale.to_s == "en"
        current = BpmnSampleFlows.invoice(locale: locale)
        current[:nodes] = current[:nodes].map do |n|
          n[:id] == "t4" ? n.merge(name: en ? "Schedule bank transfer" : "Programar transferencia bancaria") : n
        end
        current[:nodes] << { id: "t5", type: "send_task", lane_id: "l2", name: en ? "Notify the supplier" : "Notificar al proveedor" }
        current[:annotations] = [
          { id: "a1", target_id: "t1", number: 1, tag: "question",
            text: en ? "Who validates invoices from abroad?" : "¿Quién valida las facturas del extranjero?" },
          { id: "a2", target_id: "t4", number: 2, tag: "keep",
            text: en ? "Automated next quarter." : "Se automatiza el próximo trimestre." }
        ]
        previous = BpmnSampleFlows.invoice(locale: locale)
        previous[:nodes] << { id: "t0", type: "task", lane_id: "l2", name: en ? "Print invoice" : "Imprimir factura" }
        flow = ProcessFlow.reset!("Review (#{locale})", current)
        path = Rails.application.routes.url_helpers.admin_process_flow_diagram_path(flow)
        urls = { save: path, diagram: path }
        island(locale, data: flow.to_diagram(locale: locale), editable: editable, urls: editable ? urls : {},
                       name: en ? "Supplier payments" : "Pago a proveedores",
                       watermark: en ? "Draft" : "Borrador",
                       review: {
                         tags: [ { key: "question", label: en ? "Question" : "Pregunta", color: "#2563eb" },
                                 { key: "keep", label: en ? "Keep" : "Mantener", color: "#16a34a" } ],
                         compare_with: { document: previous, label: en ? "Published v1.0" : "Vigente v1.0" }
                       })
      end

      # @label Catalog of elements
      # Every element of the palette, grouped as the palette groups them: its
      # icon and its canvas shape (one drawing, shapes.jsx), then a table with
      # what it is, when to use it, what this editor does with it, the rules
      # that check it and the palette presets it is in. The texts are the
      # island's own strings (palette_<key>_summary/_when/_editor) and the
      # rules come from their `appliesTo`. docs/api/bpmn-editor.md#palette
      # @param locale select { choices: [es, en] }
      # @param theme select "Page theme" { choices: [light, dark] }
      def catalog(locale: :es, theme: "light")
        I18n.with_locale(locale) do
          data = BpmnSampleFlows.catalog(Bali::BpmnEditor::Translations.island(locale: locale))
          render_with_template(
            template: "bali/bpmn_editor/previews/catalog",
            locals: { component: Bali::BpmnEditor::Component.new(data: data), groups: BpmnElementCatalog.groups(locale),
                      locale: locale, theme: theme.to_s }
          )
        end
      end

      # @label Two editors on one page
      # Two editors of the same flow, each with its own id: an event the app
      # sends to one (a linked sub-process, a reload) reaches that one only.
      # docs/api/bpmn-editor.md#extension-points
      # @param locale select { choices: [es, en] }
      def pair(locale: :es)
        data = BpmnSampleFlows.invoice(locale: locale)
        data[:nodes] << { id: "sp", type: "sub_process", lane_id: "l3", name: locale.to_s == "en" ? "Procedure" : "Procedimiento" }
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/pair",
            locals: { first: Bali::BpmnEditor::Component.new(data: data, id: "first_bpmn"),
                      second: Bali::BpmnEditor::Component.new(data: data, id: "second_bpmn") }
          )
        end
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
        sample = BpmnRuleExamples.example(rule, example, locale: locale)
        flow = ProcessFlow.find_or_initialize_by(name: "Rules gallery")
        flow.update!(document: sample[:document], version: 1, finalized_at: nil)
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/rules_gallery",
            locals: { flow: flow, rule: rule, example: example.to_s, optional: optional,
                      optional_rules: optional_rules, sample: sample, locale: locale }
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
