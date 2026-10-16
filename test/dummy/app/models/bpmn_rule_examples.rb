# frozen_string_literal: true

# The rules gallery preview's examples: per rule of Bali::BpmnEditor, a flow
# that breaks it and one that does not. Read from the file the JS tests read
# (test/fixtures/bpmn_editor/rule_examples.json, through
# test/javascript/bpmn_editor/support/ruleExamples.js), so each example exists
# once. A document given as a string names one in the file's `documents`.
module BpmnRuleExamples
  module_function

  PATH = Bali::Engine.root.join("test/fixtures/bpmn_editor/rule_examples.json")
  EXAMPLES = %w[failing passing].freeze

  def file
    @file ||= JSON.parse(PATH.read)
  end

  # Every rule with an example, the optional package's included.
  def rule_ids
    file["rules"].keys
  end

  # The rules that run only when the optional package is loaded.
  def optional_rule_ids
    file["rules"].select { |_id, example| example["package"] == "optional" }.keys
  end

  # { document:, options:, allowed:, page: } for `rule`'s failing or passing
  # example, its texts in `locale` (the file keeps every text as { en, es }, so
  # the word lists of the page's language check words of that language).
  # The options, palette and sheet are what make the failing example break the
  # rule (R19, R20, VIS-10, VIS-02 on an otherwise clean flow); the passing one
  # runs with the defaults.
  def example(rule, which, locale: I18n.locale)
    entry = file["rules"].fetch(rule.to_s)
    raise ArgumentError, "example must be one of #{EXAMPLES.inspect}, got #{which.inspect}" if EXAMPLES.exclude?(which.to_s)

    document = entry[which.to_s]
    document = file["documents"].fetch(document) if document.is_a?(String)
    host = which.to_s == "failing" ? entry.slice("options", "allowed", "page") : {}
    { document: BpmnSampleFlows.localize(document, locale.to_s), options: host["options"], allowed: host["allowed"],
      page: host["page"] }
  end
end
