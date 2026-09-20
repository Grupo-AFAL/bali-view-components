# frozen_string_literal: true

# Pure Ruby reimplementation of the @blocknote/xl-ai server-side logic.
# Replaces the Node.js ai-chat.mjs server with a Rails concern that:
#   1. Injects document state into messages (injectDocumentStateMessages)
#   2. Converts UI Message format to Anthropic API format
#   3. Provides the system prompt from aiDocumentFormats.html
module BlocknoteAi
  extend ActiveSupport::Concern

  # System prompt from @blocknote/xl-ai aiDocumentFormats.html.systemPrompt
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You're manipulating a text document using HTML blocks.
    Make sure to follow the json schema provided. When referencing ids they MUST be EXACTLY the same (including the trailing $).
    List items are 1 block with 1 list item each, so block content `<ul><li>item1</li></ul>` is valid, but `<ul><li>item1</li><li>item2</li></ul>` is invalid. We'll merge them automatically.
    For code blocks, you can use the `data-language` attribute on a <code> block (wrapped with <pre>) to specify the language.

    If the user requests updates to the document, use the "applyDocumentOperations" tool to update the document.
    ---
    IF there is no selection active in the latest state, first, determine what part of the document the user is talking about. You SHOULD probably take cursor info into account if needed.
      EXAMPLE: if user says "below" (without pointing to a specific part of the document) he / she probably indicates the block(s) after the cursor.
      EXAMPLE: If you want to insert content AT the cursor position (UNLESS indicated otherwise by the user), then you need `referenceId` to point to the block before the cursor with position `after` (or block below and `before`
    ---
  PROMPT

  private

  # Reimplements injectDocumentStateMessages from @blocknote/xl-ai.
  # For each user message with documentState metadata, inserts an assistant
  # message before it containing the document state as text parts.
  def inject_document_state(messages)
    messages.flat_map do |msg|
      doc_state = msg.dig("metadata", "documentState")
      next [ msg ] unless msg["role"] == "user" && doc_state

      assistant_msg = {
        "role" => "assistant",
        "id" => "assistant-document-state-#{msg['id']}",
        "parts" => document_state_parts(doc_state)
      }

      [ assistant_msg, msg ]
    end
  end

  # Converts UI messages (with parts[]) to Anthropic API messages (with content[]).
  # Handles text parts and tool-invocation parts, ensures alternating roles,
  # and prepends a synthetic user message if needed (Anthropic requires user-first).
  def to_anthropic_messages(messages)
    raw = []

    messages.each do |msg|
      role = msg["role"] == "user" ? "user" : "assistant"
      parts = msg["parts"] || []

      content_blocks = []
      tool_results = []

      parts.each do |part|
        case part["type"]
        when "text"
          content_blocks << { type: "text", text: part["text"] }
        when "tool-invocation"
          content_blocks << {
            type: "tool_use",
            id: part["toolCallId"],
            name: part["toolName"],
            input: part["input"] || {}
          }

          if part["state"] == "result" && part.key?("output")
            output = part["output"]
            tool_results << {
              type: "tool_result",
              tool_use_id: part["toolCallId"],
              content: output.is_a?(String) ? output : JSON.generate(output)
            }
          end
        end
      end

      raw << { role: role, content: content_blocks } if content_blocks.any?
      raw << { role: "user", content: tool_results } if tool_results.any?
    end

    # Anthropic requires the first message to be user role
    if raw.any? && raw.first[:role] != "user"
      raw.unshift({ role: "user", content: [ { type: "text", text: "." } ] })
    end

    merge_consecutive_messages(raw)
  end

  # Converts client tool definitions to Anthropic tool format.
  # Input:  { "toolName" => { "description" => "...", "inputSchema" => {...} } }
  # Output: [{ name: "toolName", description: "...", input_schema: {...} }]
  def to_anthropic_tools(tool_definitions)
    return [] unless tool_definitions.is_a?(Hash)

    tool_definitions.map do |name, defn|
      {
        name: name,
        description: defn["description"] || "",
        input_schema: defn["inputSchema"] || { type: "object" }
      }
    end
  end

  def document_state_parts(doc_state)
    if doc_state["selection"]
      [
        { "type" => "text", "text" => "This is the latest state of the selection (ignore previous selections, you MUST issue operations against this latest version of the selection):" },
        { "type" => "text", "text" => JSON.generate(doc_state["selectedBlocks"]) },
        { "type" => "text", "text" => "This is the latest state of the entire document (INCLUDING the selected text), \nyou can use this to find the selected text to understand the context (but you MUST NOT issue operations against this document, you MUST issue operations against the selection):" },
        { "type" => "text", "text" => JSON.generate(doc_state["blocks"]) }
      ]
    else
      qualifier = if doc_state["isEmptyDocument"]
        "Because the document is empty, YOU MUST first update the empty block before adding new blocks."
      else
        "Prefer updating existing blocks over removing and adding (but this also depends on the user's question)."
      end

      [
        { "type" => "text", "text" => "There is no active selection. This is the latest state of the document (ignore previous documents, you MUST issue operations against this latest version of the document). \nThe cursor is BETWEEN two blocks as indicated by cursor: true.\n#{qualifier}" },
        { "type" => "text", "text" => JSON.generate(doc_state["blocks"]) }
      ]
    end
  end

  # Merges consecutive messages with the same role (Anthropic requires alternating roles).
  def merge_consecutive_messages(messages)
    messages.each_with_object([]) do |msg, result|
      if result.last && result.last[:role] == msg[:role]
        result.last[:content].concat(msg[:content])
      else
        result << msg.dup
      end
    end
  end
end
