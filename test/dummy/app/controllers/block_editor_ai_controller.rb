# frozen_string_literal: true

require "net/http"

# Pure Rails replacement for the Node.js ai-chat.mjs server.
# Receives BlockNote AI requests, calls Anthropic API with streaming,
# and translates Anthropic SSE events to UI Message Stream protocol.
class BlockEditorAiController < ApplicationController
  include ActionController::Live
  include BlocknoteAi

  # BlockNote's DefaultChatTransport uses fetch() which doesn't include Rails CSRF tokens
  skip_forgery_protection only: :create

  def create
    body = JSON.parse(request.body.read)
    messages = body["messages"] || []
    tool_definitions = body["toolDefinitions"] || {}

    injected = inject_document_state(messages)
    anthropic_messages = to_anthropic_messages(injected)
    anthropic_tools = to_anthropic_tools(tool_definitions)

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    stream_anthropic(anthropic_messages, anthropic_tools)
  rescue => e
    Rails.logger.error("BlockEditor AI error: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    write_sse(type: "error", errorText: e.message) rescue nil
  ensure
    response.stream.close rescue nil
  end

  private

  def stream_anthropic(messages, tools)
    api_key = ENV.fetch("ANTHROPIC_API_KEY") { raise "ANTHROPIC_API_KEY environment variable is not set" }
    model = ENV.fetch("AI_MODEL", "claude-sonnet-4-5-20250929")

    payload = {
      model: model,
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: messages,
      tools: tools,
      tool_choice: { type: "any" },
      stream: true
    }

    uri = URI("https://api.anthropic.com/v1/messages")

    @content_blocks = {}
    @text_counter = 0
    @finish_reason = "stop"

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["X-Api-Key"] = api_key
      req["Anthropic-Version"] = "2023-06-01"
      req.body = JSON.generate(payload)

      http.request(req) do |res|
        unless res.code == "200"
          error_body = +""
          res.read_body { |chunk| error_body << chunk }
          raise "Anthropic API error (#{res.code}): #{error_body}"
        end

        write_sse(type: "start")
        write_sse(type: "start-step")

        buffer = +""
        res.read_body do |chunk|
          buffer << chunk

          while (idx = buffer.index("\n"))
            line = buffer.slice!(0, idx + 1).strip
            next if line.empty? || line.start_with?("event:")
            next unless line.start_with?("data: ")

            data = line.delete_prefix("data: ")
            next if data == "[DONE]"

            event = JSON.parse(data) rescue next
            handle_anthropic_event(event)
          end
        end
      end

      write_sse(type: "finish-step")
      write_sse(type: "finish", finishReason: @finish_reason)
      response.stream.write("data: [DONE]\n\n")
    end
  end

  def handle_anthropic_event(event)
    case event["type"]
    when "content_block_start"
      start_content_block(event["index"], event["content_block"])

    when "content_block_delta"
      delta_content_block(event["index"], event["delta"])

    when "content_block_stop"
      stop_content_block(event["index"])

    when "message_delta"
      reason = event.dig("delta", "stop_reason")
      @finish_reason = map_finish_reason(reason) if reason
    end
  end

  def start_content_block(index, block)
    case block["type"]
    when "text"
      id = "text-#{@text_counter}"
      @text_counter += 1
      @content_blocks[index] = { type: "text", id: id }
      write_sse(type: "text-start", id: id)

    when "tool_use"
      @content_blocks[index] = { type: "tool_use", id: block["id"], name: block["name"], input_json: +"" }
      write_sse(type: "tool-input-start", toolCallId: block["id"], toolName: block["name"])
    end
  end

  def delta_content_block(index, delta)
    block = @content_blocks[index]
    return unless block

    case delta["type"]
    when "text_delta"
      write_sse(type: "text-delta", id: block[:id], delta: delta["text"])

    when "input_json_delta"
      json_chunk = delta["partial_json"]
      block[:input_json] << json_chunk
      write_sse(type: "tool-input-delta", toolCallId: block[:id], inputTextDelta: json_chunk)
    end
  end

  def stop_content_block(index)
    block = @content_blocks.delete(index)
    return unless block

    case block[:type]
    when "text"
      write_sse(type: "text-end", id: block[:id])

    when "tool_use"
      input = JSON.parse(block[:input_json]) rescue {}
      write_sse(type: "tool-input-available", toolCallId: block[:id], toolName: block[:name], input: input)
    end
  end

  # Maps Anthropic stop_reason to UI Message Stream finishReason enum.
  # See @ai-sdk/anthropic mapAnthropicStopReason for the canonical mapping.
  def map_finish_reason(anthropic_reason)
    case anthropic_reason
    when "end_turn", "stop_sequence", "pause_turn" then "stop"
    when "tool_use" then "tool-calls"
    when "max_tokens", "model_context_window_exceeded" then "length"
    when "refusal" then "content-filter"
    else "other"
    end
  end

  def write_sse(**data)
    response.stream.write("data: #{JSON.generate(data)}\n\n")
  end
end
