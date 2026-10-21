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
      # @param layout select "What «Autoajustar» and the first layout do (straight here; the component's default is compact)" { choices: [straight, compact] }
      # @param page select "Sheet for the compact layout and the outputs" { choices: [letter_landscape, letter_portrait, a4_landscape, a4_portrait, legal_landscape, legal_portrait] }
      # @param lock_orientation toggle "Hide the orientation switch"
      # @param external_lanes toggle "Offer the external participant checkbox"
      # @param autosave toggle "Save after every change (off: only «Guardar borrador»)"
      # @param optional_rules toggle "Load the optional rule package"
      # @param rule_severity select "Rule configuration: default, strict, relaxed, structure (rules: :structure) or off (rules: false)" { choices: [default, strict, relaxed, structure, "off"] }
      # @param server select "How the dummy server answers (demonstration only)" { choices: [normal, conflict, error, slow, issues, reject_finalize] }
      # @param theme select "Page theme" { choices: [light, dark] }
      # @param locale select { choices: [es, en] }
      # @param name text "Title of the outputs and file name"
      # @param watermark text "Text across the outputs"
      # @param fresh toggle "Start from the sample on every visit"
      # `layout` starts straight here: a demo builds a flow step by step and
      # reads it left to right, while compact folds anything that would print
      # below 6 pt on the page (VIS-02). The component keeps `:compact`.
      def playground(sample: "invoice", orientation: "horizontal", palette: :analytic, layout: :straight,
                     page: "letter_landscape", lock_orientation: false, external_lanes: true, autosave: true,
                     optional_rules: false, rule_severity: "default", server: "normal", theme: "light",
                     locale: :es, name: "", watermark: "", fresh: true)
        flow = ProcessFlow.for_sample(sample.to_s, locale: locale, fresh: fresh, orientation: orientation.to_s)
        render_with_template(
          template: "bali/bpmn_editor/previews/playground",
          locals: { flow: flow, locale: locale, theme: theme.to_s, optional_rules: optional_rules, server: server.to_s,
                    options: { palette: palette.to_sym, layout: layout.to_sym, page: PAGES.fetch(page.to_s),
                               lock_orientation: lock_orientation, external_lanes: external_lanes,
                               autosave: autosave, rules: { "off" => false, "structure" => :structure }.fetch(rule_severity.to_s) { RULE_PRESETS.fetch(rule_severity.to_s) },
                               name: name.presence, watermark: watermark.presence } }
        )
      end

      # @label Read-only viewer
      # No `editable:` and no `urls:`: a diagram to look at. Three lanes, the
      # first an external participant (grey lane, white activities), a message
      # flow, a decision with labelled answers and an annotation. Try zooming,
      # «Pantalla completa», the outputs, and clicking a sub-process with a link.
      # With `appearance` on, the app colours three elements, fades one and
      # badges two (`node.appearance`), and explains its colours in the legend;
      # the outputs carry them too. With badges, «Show badges» beside the
      # canvas shows and hides them (`badges:` — shown on load or not —,
      # `badge_toggle:` — the switch offered or not). docs/api/bpmn-editor.md
      # @param appearance toggle "The app's colours, fading and badges on some elements"
      # @param badges toggle "Badges shown on load"
      # `badge_toggle_label` gives the switch the app's own words. `wheel_zoom`:
      # the editor is the page here, so the wheel zooms it (`true`); `auto` is
      # what a read-only diagram among a page's content gets — the wheel
      # scrolls the page and Ctrl (⌘) + wheel zooms, as in the catalog — and
      # `false` never zooms with the wheel.
      # @param badge_toggle toggle "Offer «Show badges»"
      # @param badge_toggle_label text "The switch's own label (empty: the default one)"
      # @param wheel_zoom select { choices: [true, auto, false] }
      # @param locale select { choices: [es, en] }
      def default(appearance: false, badges: true, badge_toggle: true, badge_toggle_label: "", wheel_zoom: "true", locale: :es)
        data = BpmnSampleFlows.invoice(locale: locale)
        wheel = { "true" => true, "false" => false }.fetch(wheel_zoom.to_s, :auto)
        return island(locale, data: data, wheel_zoom: wheel) unless appearance

        en = locale.to_s == "en"
        looks = { "t1" => { color: "#E9A23B", badge: en ? "In progress" : "En proceso" },
                  "t3" => { color: "#16a34a", badge: en ? "Done" : "Hecho" },
                  "t4" => { color: "#2563eb" }, "p1" => { dimmed: true } }
        data[:nodes] = data[:nodes].map { |n| looks[n[:id]] ? n.merge(appearance: looks[n[:id]]) : n }
        # A long-named linked sub-process with a badge: its name keeps clear of
        # the tab, the [+] and the corners.
        insurance = en ? "Manage insurance and claims for company fixed assets" : "Gestión de seguros y siniestros de activos fijos"
        data[:nodes] << { id: "sp", type: "sub_process", lane_id: "l3", name: insurance,
                          reference: { id: "insurance", label: insurance, url: "/lookbook/preview/bali/bpmn_editor/default" },
                          appearance: { color: "#16a34a", badge: en ? "Complete" : "Completo" } }
        data[:edges] = data[:edges].map { |e| e[:id] == "f6" ? e.merge(target: "sp") : e } << { id: "f7", source: "sp", target: "e1" }
        toggle = badge_toggle && badge_toggle_label.present? ? badge_toggle_label : badge_toggle
        island(locale, data: data, badges: badges, badge_toggle: toggle, wheel_zoom: wheel, legend: { add: [
                 { key: "app_progress", label: en ? "In progress" : "En proceso", swatch: "color", color: "#E9A23B" },
                 { key: "app_done", label: en ? "Done" : "Hecho", swatch: "color", color: "#16a34a" },
                 { key: "app_automated", label: en ? "Automated" : "Automatizado", swatch: "color", color: "#2563eb" }
               ] })
      end

      # @label Host integration
      # What the app around the editor does: a console of the `bali-bpmn:*`
      # events the editors send (dirty-change, saved, finalized, open-reference,
      # with their detail), buttons that answer through the Turbo Stream helpers
      # (`bali_bpmn_reload`, `bali_bpmn_reference_created`) against one editor's
      # id, the read-only pattern (an alert the app composes above a locked
      # editor) and two flows in tabs whose label marks unsaved changes from
      # `bali-bpmn:dirty-change`. The console and the tabs' mark are the dummy's
      # own Stimulus controller, not the component's. The editors sit among
      # the page's content, so the wheel scrolls the page over the read-only
      # one (`wheel_zoom: :auto`; Ctrl or ⌘ + wheel zooms it).
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
      # properties panel; they are saved to this preview's own record. The
      # editor is the page, so the wheel zooms it (`wheel_zoom: true`).
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
                       watermark: en ? "Draft" : "Borrador", wheel_zoom: true,
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
      # Each sits in a box of its own, so the page tells them the wheel zooms
      # (`wheel_zoom: true`).
      # docs/api/bpmn-editor.md#extension-points
      # @param locale select { choices: [es, en] }
      def pair(locale: :es)
        data = BpmnSampleFlows.invoice(locale: locale)
        data[:nodes] << { id: "sp", type: "sub_process", lane_id: "l3", name: locale.to_s == "en" ? "Procedure" : "Procedimiento" }
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/pair",
            locals: { first: Bali::BpmnEditor::Component.new(data: data, id: "first_bpmn", wheel_zoom: true),
                      second: Bali::BpmnEditor::Component.new(data: data, id: "second_bpmn", wheel_zoom: true) }
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

      # @label Split view: a map and the flow behind each box
      # The «50/50» pattern inside a collapsible `Bali::SplitView`: the map
      # alone at first, and the flow behind a box slides in beside it when the
      # box is clicked; «Close» or Esc give the map the width back and clear its
      # selection. The map is a map of processes in vertical lanes whose boxes
      # the APP colours (`appearance:` — colour, faded, badge) and explains in
      # the legend (`swatch: "color"`); `chrome: :minimal`, `rules: :structure`
      # (a map is no process model). The flow is read-only with `chrome:
      # :minimal` and `annotatable:` (select an element and add a note: it is
      # saved to `urls[:annotations]`).
      #
      # The detail is lazy, as in an app: a click points the SplitView's frame
      # at the dummy's `/bpmn_flows/:box` (the flow, its versions and the
      # header), and the pane opens at once with its loading state until the
      # response lands. The wiring is the dummy app's own Stimulus controller:
      # it listens to `bali-bpmn:selection-change` on the map, takes
      # `bali-bpmn:open-reference` over so a click only selects, and moves the
      # map with `bali-bpmn:select` from «Previous» / «Next»; those and the
      # version picker fetch too. `selected` is a deep link: the map's
      # `selected_id:`, whose flow the controller opens on load. `delay` holds
      # every response back, to watch the loading state.
      # docs/api/bpmn-editor.md#embedding-a-diagram
      # `master_width: :equal` and `height: :screen` by default: the two panes
      # the same width, and as tall as the window leaves them.
      # @param locale select { choices: [es, en] }
      # @param selected select { choices: [~, b1, b2, b3, b4, b5, b6] }
      # @param height select { choices: [screen, full, content, 640px] }
      # @param master_width select { choices: [equal, 50%, 420px] }
      # @param badges toggle "The map's badges shown on load (the flows on the right have none, so they offer no switch)"
      # @param delay select "Milliseconds each detail response is held back" { choices: [0, 300, 800, 2000] }
      def split_view(locale: :es, selected: nil, height: "screen", master_width: "equal", badges: true, delay: 0)
        # Every load starts from the samples: notes added before are dropped.
        BpmnProcessMap.flow_records(locale, fresh: true)
        I18n.with_locale(locale) do
          render_with_template(template: "bali/bpmn_editor/previews/split_view",
                               locals: { locale: locale, selected: selected.presence,
                                         height: split_option(height), master_width: split_option(master_width),
                                         badges: badges, delay: delay.to_i })
        end
      end

      # @label Compare flows and versions
      # «Supplier onboarding» against what an app would offer, picked in the
      # comparison bar (`compare_with:` with a list): another process that
      # shares most of its steps («Customer onboarding», «Employee
      # onboarding») and its own previous version, once with stable ids and
      # once with every id recreated (as a destructive import leaves them).
      # All use `match: :auto` — by id, then by name — so the recreated version
      # still pairs. Side by side by default, zoom and panning in sync; the
      # overlay is offered only for versions of one process. Hover an element
      # to see its counterpart; «Solo cambios» fades what did not change.
      # The editor is the page here, so the wheel zooms it before comparing
      # too (`wheel_zoom: true`; with `:auto` a read-only diagram leaves the
      # wheel to the page).
      # docs/api/bpmn-editor.md#outputs-notes-and-comparison
      # @param locale select { choices: [es, en] }
      def compare_flows(locale: :es)
        en = locale.to_s == "en"
        options = [
          { document: BpmnProcessMap.customer(locale), label: en ? "Customer onboarding" : "Alta de cliente" },
          { document: BpmnProcessMap.employee(locale), label: en ? "Employee onboarding" : "Alta de empleado" },
          { document: BpmnProcessMap.supplier(locale, version: 1), label: en ? "v1 (stable ids)" : "v1 (ids estables)" },
          { document: BpmnProcessMap.recreated(BpmnProcessMap.supplier(locale, version: 1)),
            label: en ? "v1 (recreated ids)" : "v1 (ids recreados)" }
        ]
        I18n.with_locale(locale) do
          render_with_template(
            template: "bali/bpmn_editor/previews/compare_flows",
            locals: { locale: locale,
                      component: Bali::BpmnEditor::Component.new(
                        data: BpmnProcessMap.supplier(locale), rules: false, id: "compare_flows_bpmn",
                        name: en ? "Supplier onboarding" : "Alta de proveedor", review: { compare_with: options },
                        wheel_zoom: true
                      ) }
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

      # A select's value as SplitView takes it: the keywords as symbols, a
      # length as written.
      def split_option(value)
        %w[equal screen full content].include?(value.to_s) ? value.to_sym : value.to_s
      end
    end
  end
end
