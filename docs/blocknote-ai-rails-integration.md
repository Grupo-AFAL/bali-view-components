# BlockNote AI: Pure Rails Implementation (No Node.js Process)

## Problem Statement

The gobierno-corporativo app currently spawns a **separate Node.js process per AI request** to handle BlockNote's `/ai` feature. The controller (`Documents::AiCompletionsController`) uses `Open3.popen3("node", "lib/ai/blocknote-chat.mjs")` to:

1. Transform messages (inject document state)
2. Call the Anthropic API via the Vercel AI SDK
3. Stream the response in the UI Message Stream protocol

This approach works but has downsides:
- **Per-request process spawn overhead** (~100-200ms per Node.js cold start)
- **Requires Node.js on the server** just for this one feature
- **Dependency duplication** (`@ai-sdk/anthropic`, `ai`, `@blocknote/xl-ai` installed server-side)
- **Error handling complexity** (piping stdin/stdout/stderr across process boundaries)

## Architecture Analysis

### Current Flow

```
Browser (BlockNote AI)
  │
  │ POST /documents/ai_completion
  │ Body: { messages: UIMessage[], toolDefinitions: ToolDefinitions }
  │
  ▼
Rails Controller (ActionController::Live)
  │
  │ Open3.popen3("node", "blocknote-chat.mjs")
  │ stdin.write(payload) → stdout.read → response.stream.write
  │
  ▼
Node.js Process (blocknote-chat.mjs)
  │
  ├─ injectDocumentStateMessages(messages)  ← Message transformation
  ├─ convertToModelMessages(...)            ← UIMessage → Anthropic format
  ├─ toolDefinitionsToToolSet(toolDefs)     ← JSON Schema → AI SDK tools
  ├─ streamText({ model, system, ... })     ← Anthropic API call
  └─ toUIMessageStreamResponse()            ← Stream → SSE protocol
  │
  ▼
Anthropic API (claude-sonnet-4-5-20250929)
```

### What Each Server Utility Actually Does

#### 1. `injectDocumentStateMessages(messages)`
**Pure data transformation.** For each user message containing `metadata.documentState`, inserts an assistant message BEFORE it containing the document state as text. Two modes:

- **No selection:** Injects document blocks with cursor position info
- **With selection:** Injects selected blocks + full document for context

#### 2. `toolDefinitionsToToolSet(toolDefinitions)`
**Deserialization.** Converts `{ name: { description, inputSchema, outputSchema } }` back into AI SDK `tool()` objects. The tool definitions come FROM the client and are just JSON Schema objects.

#### 3. `aiDocumentFormats.html.systemPrompt`
**Static string constant.** Instructs the LLM about HTML block manipulation rules. See [System Prompt](#system-prompt) below.

#### 4. `convertToModelMessages(messages)`
**Format conversion.** Converts UIMessage format (`{ parts: [{ type, text }] }`) to Anthropic API format (`{ content: [{ type, text }] }`).

#### 5. `streamText()` + `toUIMessageStreamResponse()`
**API call + protocol conversion.** Calls Anthropic API with streaming, then converts the Anthropic SSE stream to the [UI Message Stream protocol](#ui-message-stream-protocol).

### Key Insight

**Every operation the Node.js process performs can be replicated in Ruby.** There is no client-side JavaScript dependency on the server — the server only transforms data and proxies between the browser and Anthropic.

## Proposed Solution: Pure Ruby Implementation

### New Flow

```
Browser (BlockNote AI)
  │
  │ POST /documents/ai_completion
  │ Body: { messages: UIMessage[], toolDefinitions: ToolDefinitions }
  │
  ▼
Rails Controller (ActionController::Live)
  │
  ├─ BlocknoteAi::MessageTransformer.inject_document_state(messages)
  ├─ BlocknoteAi::MessageConverter.to_anthropic_messages(messages)
  ├─ BlocknoteAi::ToolConverter.to_anthropic_tools(tool_definitions)
  ├─ Anthropic API (streaming HTTP via Net::HTTP or ruby_llm)
  └─ BlocknoteAi::StreamConverter.anthropic_to_ui_stream(response, output)
  │
  ▼
Anthropic API (claude-sonnet-4-5-20250929)
```

### Implementation

#### File Structure

```
app/
├── controllers/documents/
│   └── ai_completions_controller.rb  (simplified, no Open3)
└── lib/blocknote_ai/                 (or app/services/blocknote_ai/)
    ├── message_transformer.rb        # injectDocumentStateMessages
    ├── message_converter.rb          # convertToModelMessages
    ├── tool_converter.rb             # toolDefinitionsToToolSet
    ├── stream_converter.rb           # Anthropic SSE → UI Message Stream
    └── system_prompt.rb              # Static system prompt constant
```

#### 1. System Prompt (`system_prompt.rb`)

```ruby
# frozen_string_literal: true

module BlocknoteAi
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
end
```

#### 2. Message Transformer (`message_transformer.rb`)

Reimplements `injectDocumentStateMessages`:

```ruby
# frozen_string_literal: true

module BlocknoteAi
  class MessageTransformer
    # Injects document state from message metadata into the conversation flow.
    # For each user message with documentState metadata, inserts an assistant
    # message BEFORE it containing the document state as text.
    def self.inject_document_state(messages)
      messages.flat_map do |message|
        document_state = message.dig("metadata", "documentState")

        if message["role"] == "user" && document_state.present?
          [build_state_message(message["id"], document_state), message]
        else
          [message]
        end
      end
    end

    private_class_method def self.build_state_message(user_message_id, state)
      parts = if state["selection"]
                selection_parts(state)
              else
                no_selection_parts(state)
              end

      {
        "role" => "assistant",
        "id" => "assistant-document-state-#{user_message_id}",
        "parts" => parts
      }
    end

    private_class_method def self.selection_parts(state)
      [
        { "type" => "text", "text" => "This is the latest state of the selection (ignore previous selections, you MUST issue operations against this latest version of the selection):" },
        { "type" => "text", "text" => state["selectedBlocks"].to_json },
        { "type" => "text", "text" => "This is the latest state of the entire document (INCLUDING the selected text), you can use this to find the selected text to understand the context (but you MUST NOT issue operations against this document, you MUST issue operations against the selection):" },
        { "type" => "text", "text" => state["blocks"].to_json }
      ]
    end

    private_class_method def self.no_selection_parts(state)
      preamble = "There is no active selection. This is the latest state of the document (ignore previous documents, you MUST issue operations against this latest version of the document).\nThe cursor is BETWEEN two blocks as indicated by cursor: true.\n"

      preamble += if state["isEmptyDocument"]
                    "Because the document is empty, YOU MUST first update the empty block before adding new blocks."
                  else
                    "Prefer updating existing blocks over removing and adding (but this also depends on the user's question)."
                  end

      [
        { "type" => "text", "text" => preamble },
        { "type" => "text", "text" => state["blocks"].to_json }
      ]
    end
  end
end
```

#### 3. Message Converter (`message_converter.rb`)

Converts UIMessages (with `parts` array) to Anthropic API format (with `content` array):

```ruby
# frozen_string_literal: true

module BlocknoteAi
  class MessageConverter
    # Converts UIMessage format to Anthropic API messages format.
    # UIMessages use { parts: [{ type: "text", text: "..." }] }
    # Anthropic uses { content: [{ type: "text", text: "..." }] }
    def self.to_anthropic_messages(messages)
      messages.filter_map do |msg|
        content = convert_parts(msg["parts"] || [])
        next if content.empty?

        { role: msg["role"], content: content }
      end
    end

    private_class_method def self.convert_parts(parts)
      parts.filter_map do |part|
        case part["type"]
        when "text"
          { type: "text", text: part["text"] }
        when "tool-call"
          {
            type: "tool_use",
            id: part["toolCallId"],
            name: part["toolName"],
            input: part["args"] || {}
          }
        when "tool-result"
          {
            type: "tool_result",
            tool_use_id: part["toolCallId"],
            content: part["result"].is_a?(String) ? part["result"] : part["result"].to_json
          }
        end
      end
    end
  end
end
```

#### 4. Tool Converter (`tool_converter.rb`)

Converts client tool definitions to Anthropic API tool format:

```ruby
# frozen_string_literal: true

module BlocknoteAi
  class ToolConverter
    # Converts BlockNote tool definitions to Anthropic API tool format.
    # Input:  { "toolName" => { "description" => "...", "inputSchema" => {...} } }
    # Output: [{ name: "toolName", description: "...", input_schema: {...} }]
    def self.to_anthropic_tools(tool_definitions)
      return [] if tool_definitions.blank?

      tool_definitions.map do |name, definition|
        {
          name: name,
          description: definition["description"] || "",
          input_schema: definition["inputSchema"]
        }
      end
    end
  end
end
```

#### 5. Stream Converter (`stream_converter.rb`)

Maps Anthropic's SSE events to the UI Message Stream protocol:

```ruby
# frozen_string_literal: true

module BlocknoteAi
  class StreamConverter
    # Converts Anthropic streaming events to UI Message Stream protocol.
    #
    # Anthropic events:
    #   message_start           → start
    #   content_block_start     → text-start / tool-input-start
    #   content_block_delta     → text-delta / tool-input-delta
    #   content_block_stop      → text-end / tool-input-available
    #   message_stop            → finish + [DONE]
    #
    # UI Message Stream format:
    #   data: {"type":"start","messageId":"msg_123"}\n\n
    #   data: {"type":"tool-input-start","toolCallId":"...","toolName":"..."}\n\n
    #   data: {"type":"tool-input-delta","toolCallId":"...","inputTextDelta":"..."}\n\n
    #   data: {"type":"tool-input-available","toolCallId":"...","toolName":"...","input":{...}}\n\n
    #   data: {"type":"finish"}\n\n
    #   data: [DONE]\n\n

    def initialize(response_stream)
      @stream = response_stream
      @current_block = nil        # Tracks current content block being streamed
      @tool_input_buffer = ""     # Accumulates tool input JSON for tool-input-available
      @message_id = nil
    end

    def write_event(data)
      if data.is_a?(String)
        @stream.write("data: #{data}\n\n")
      else
        @stream.write("data: #{data.to_json}\n\n")
      end
    end

    def handle_event(event_type, data)
      case event_type
      when "message_start"
        @message_id = data.dig("message", "id") || SecureRandom.uuid
        write_event({ type: "start", messageId: @message_id })

      when "content_block_start"
        block = data["content_block"]
        @current_block = block
        @tool_input_buffer = ""

        case block["type"]
        when "text"
          write_event({ type: "text-start", id: block["id"] || "text-#{data["index"]}" })
        when "tool_use"
          write_event({
            type: "tool-input-start",
            toolCallId: block["id"],
            toolName: block["name"]
          })
        end

      when "content_block_delta"
        delta = data["delta"]

        case delta["type"]
        when "text_delta"
          block_id = @current_block&.dig("id") || "text-#{data["index"]}"
          write_event({ type: "text-delta", id: block_id, delta: delta["text"] })
        when "input_json_delta"
          @tool_input_buffer += delta["partial_json"]
          write_event({
            type: "tool-input-delta",
            toolCallId: @current_block["id"],
            inputTextDelta: delta["partial_json"]
          })
        end

      when "content_block_stop"
        if @current_block
          case @current_block["type"]
          when "text"
            block_id = @current_block["id"] || "text-#{data["index"]}"
            write_event({ type: "text-end", id: block_id })
          when "tool_use"
            parsed_input = @tool_input_buffer.present? ? JSON.parse(@tool_input_buffer) : {}
            write_event({
              type: "tool-input-available",
              toolCallId: @current_block["id"],
              toolName: @current_block["name"],
              input: parsed_input
            })
          end
        end
        @current_block = nil
        @tool_input_buffer = ""

      when "message_stop"
        write_event({ type: "finish" })
        write_event("[DONE]")
      end
    rescue => e
      Rails.logger.error("StreamConverter error: #{e.class}: #{e.message}")
      write_event({ type: "error", errorText: "Internal streaming error" })
    end
  end
end
```

#### 6. Revised Controller

```ruby
# frozen_string_literal: true

class Documents::AiCompletionsController < ApplicationController
  include ActionController::Live

  skip_before_action :verify_authenticity_token, only: :create

  MODEL = "claude-sonnet-4-5-20250929"
  API_URL = "https://api.anthropic.com/v1/messages"

  def create
    authorize Document.new, :create?

    response.headers["Content-Type"] = "text/event-stream; charset=utf-8"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"
    response.headers["x-vercel-ai-ui-message-stream"] = "v1"

    payload = JSON.parse(request.body.read)
    messages = payload["messages"] || []
    tool_definitions = payload["toolDefinitions"] || {}

    # 1. Inject document state into messages
    transformed = BlocknoteAi::MessageTransformer.inject_document_state(messages)

    # 2. Convert to Anthropic format
    anthropic_messages = BlocknoteAi::MessageConverter.to_anthropic_messages(transformed)

    # 3. Convert tool definitions
    tools = BlocknoteAi::ToolConverter.to_anthropic_tools(tool_definitions)

    # 4. Stream from Anthropic API
    converter = BlocknoteAi::StreamConverter.new(response.stream)

    stream_anthropic_request(
      messages: anthropic_messages,
      tools: tools,
      converter: converter
    )
  rescue ActionController::Live::ClientDisconnected
    # Client disconnected
  rescue => e
    Rails.logger.error("AI completion error: #{e.class}: #{e.message}")
  ensure
    response.stream.close
  end

  private

  def stream_anthropic_request(messages:, tools:, converter:)
    uri = URI(API_URL)

    body = {
      model: MODEL,
      max_tokens: 4096,
      system: BlocknoteAi::SYSTEM_PROMPT,
      messages: messages,
      tools: tools,
      tool_choice: { type: "any" },
      stream: true
    }

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-api-key"] = ENV.fetch("ANTHROPIC_API_KEY")
      request["anthropic-version"] = "2023-06-01"
      request.body = body.to_json

      http.request(request) do |api_response|
        buffer = ""

        api_response.read_body do |chunk|
          buffer += chunk

          while (line_end = buffer.index("\n"))
            line = buffer.slice!(0..line_end).strip
            next if line.empty?

            if line.start_with?("data: ")
              data_str = line[6..]
              next if data_str == "[DONE]"

              begin
                event_data = JSON.parse(data_str)
                converter.handle_event(event_data["type"], event_data)
              rescue JSON::ParserError
                # Skip malformed JSON
              end
            end
          end
        end
      end
    end
  end
end
```

## System Prompt

The system prompt is a static string extracted from `@blocknote/xl-ai`:

```
You're manipulating a text document using HTML blocks.
Make sure to follow the json schema provided. When referencing ids they MUST
be EXACTLY the same (including the trailing $).
List items are 1 block with 1 list item each, so block content
`<ul><li>item1</li></ul>` is valid, but `<ul><li>item1</li><li>item2</li></ul>`
is invalid. We'll merge them automatically.
For code blocks, you can use the `data-language` attribute on a <code> block
(wrapped with <pre>) to specify the language.

If the user requests updates to the document, use the "applyDocumentOperations"
tool to update the document.
---
IF there is no selection active in the latest state, first, determine what part
of the document the user is talking about. You SHOULD probably take cursor info
into account if needed.
  EXAMPLE: if user says "below" (without pointing to a specific part of the
  document) he / she probably indicates the block(s) after the cursor.
  EXAMPLE: If you want to insert content AT the cursor position (UNLESS
  indicated otherwise by the user), then you need `referenceId` to point to
  the block before the cursor with position `after` (or block below and `before`
---
```

## UI Message Stream Protocol

The UI Message Stream protocol uses Server-Sent Events (SSE) with the header `x-vercel-ai-ui-message-stream: v1`. Each line is `data: {json}\n\n`.

### Event Types

| Event | Purpose | Fields |
|-------|---------|--------|
| `start` | Begin message | `messageId` |
| `text-start` | Begin text block | `id` |
| `text-delta` | Text chunk | `id`, `delta` |
| `text-end` | End text block | `id` |
| `tool-input-start` | Begin tool call | `toolCallId`, `toolName` |
| `tool-input-delta` | Tool input chunk | `toolCallId`, `inputTextDelta` |
| `tool-input-available` | Tool call complete | `toolCallId`, `toolName`, `input` |
| `finish` | Message complete | (none) |
| `[DONE]` | Stream end | (raw string) |

### Anthropic → UI Message Stream Mapping

| Anthropic Event | UI Message Stream Event |
|----------------|------------------------|
| `message_start` | `start` |
| `content_block_start` (text) | `text-start` |
| `content_block_delta` (text_delta) | `text-delta` |
| `content_block_stop` (text) | `text-end` |
| `content_block_start` (tool_use) | `tool-input-start` |
| `content_block_delta` (input_json_delta) | `tool-input-delta` |
| `content_block_stop` (tool_use) | `tool-input-available` |
| `message_stop` | `finish` + `[DONE]` |

## Migration Steps

### 1. Add the `blocknote_ai` module (no gem changes needed)

Create the files under `app/lib/blocknote_ai/` (or `app/services/blocknote_ai/`):
- `system_prompt.rb`
- `message_transformer.rb`
- `message_converter.rb`
- `tool_converter.rb`
- `stream_converter.rb`

### 2. Update the controller

Replace `Open3.popen3("node", ...)` with direct Anthropic API calls using the new module.

### 3. Remove the Node.js script

Delete `lib/ai/blocknote-chat.mjs`.

### 4. Remove server-side JS dependencies

These npm packages are only needed for the server-side Node.js script and can be removed from `package.json`:
- `@ai-sdk/anthropic` (only used in `blocknote-chat.mjs`)
- The `ai` package import used in `blocknote-chat.mjs` (note: the `ai` package is also used client-side by the `DefaultChatTransport`, so **keep it**)

**Keep these** (used client-side by Bali BlockEditor):
- `@blocknote/xl-ai` (client-side AI extension)
- `ai` (client-side `DefaultChatTransport`)

Actually, `@ai-sdk/anthropic` is only used server-side. Remove it:
```bash
yarn remove @ai-sdk/anthropic
```

### 5. Set environment variable

Ensure `ANTHROPIC_API_KEY` is set in the Rails environment (it likely already is since `ruby_llm` uses it).

### 6. No frontend changes needed

The Bali `BlockEditorController` already sends `aiUrl` to the `DefaultChatTransport`. The transport makes a standard HTTP POST and reads the SSE stream. The Ruby implementation produces the exact same protocol — the frontend is completely unaware of the change.

## Testing Strategy

### Unit Tests

```ruby
# test/lib/blocknote_ai/message_transformer_test.rb
class BlocknoteAi::MessageTransformerTest < ActiveSupport::TestCase
  test "injects document state for user messages with metadata" do
    messages = [{
      "id" => "msg_1",
      "role" => "user",
      "parts" => [{ "type" => "text", "text" => "Make bold" }],
      "metadata" => {
        "documentState" => {
          "selection" => false,
          "isEmptyDocument" => false,
          "blocks" => [{ "id" => "block1$", "block" => "<p>Hello</p>" }]
        }
      }
    }]

    result = BlocknoteAi::MessageTransformer.inject_document_state(messages)

    assert_equal 2, result.length
    assert_equal "assistant", result[0]["role"]
    assert_equal "user", result[1]["role"]
  end

  test "passes through messages without document state" do
    messages = [{
      "id" => "msg_1",
      "role" => "user",
      "parts" => [{ "type" => "text", "text" => "Hello" }]
    }]

    result = BlocknoteAi::MessageTransformer.inject_document_state(messages)
    assert_equal 1, result.length
  end
end
```

### Integration Test

```ruby
# test/controllers/documents/ai_completions_controller_test.rb
class Documents::AiCompletionsControllerTest < ActionDispatch::IntegrationTest
  test "streams AI response without Node.js" do
    sign_in users(:admin)

    stub_anthropic_streaming do
      post documents_ai_completion_path,
        params: { messages: [], toolDefinitions: {} }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :success
      assert_equal "text/event-stream; charset=utf-8", response.content_type
    end
  end
end
```

## Alternative Approaches Considered

### A. Using `ruby_llm` gem instead of raw HTTP

The app already uses `ruby_llm`. However, `ruby_llm`'s streaming API returns text chunks, not raw SSE events. We need access to the raw Anthropic SSE events (message_start, content_block_start, etc.) to map them to the UI Message Stream protocol. Raw `Net::HTTP` gives us this control.

If `ruby_llm` adds raw event access in the future, the `stream_anthropic_request` method could be simplified.

### B. Persistent Node.js worker (socket-based)

Instead of spawning per-request, keep a persistent Node.js process with a Unix socket. Rejected because it still requires Node.js and adds operational complexity.

### C. ExecJS / MiniRacer (embedded JS runtime)

Run the JS utilities inside Ruby via an embedded V8 engine. Rejected because:
- The AI SDK uses `fetch()` and `ReadableStream` (Web APIs not available in V8)
- Would need to mock/polyfill the entire Web platform
- Adds more complexity than reimplementing the simple utilities in Ruby

## Performance Comparison

| Metric | Current (Node.js) | Proposed (Pure Ruby) |
|--------|-------------------|---------------------|
| Process spawn | ~100-200ms per request | 0ms |
| Memory per request | ~50-80MB (Node.js V8) | ~0 (shared Rails process) |
| Dependencies | Node.js + 3 npm packages | 0 additional |
| Streaming latency | stdin→stdout pipe | Direct HTTP stream |
| Error handling | Cross-process stderr | Standard Ruby exceptions |

## References

- [BlockNote AI Docs](https://www.blocknotejs.org/docs/features/ai)
- [BlockNote AI Getting Started](https://www.blocknotejs.org/docs/features/ai/getting-started)
- [BlockNote AI Custom Commands](https://www.blocknotejs.org/docs/features/ai/custom-commands)
- [AI SDK Stream Protocol](https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol)
- [Anthropic Streaming API](https://docs.anthropic.com/en/api/messages-streaming)
- [BlockNote xl-ai source](https://github.com/TypeCellOS/BlockNote/tree/main/packages/xl-ai)
