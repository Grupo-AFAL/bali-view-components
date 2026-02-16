/**
 * BlockEditor AI Chat Server
 *
 * Standalone Node.js server that provides the AI backend for the BlockEditor
 * component's @blocknote/xl-ai integration. Uses the Vercel AI SDK with
 * Anthropic's Claude as the LLM provider.
 *
 * Usage:
 *   ANTHROPIC_API_KEY=sk-ant-... node server/ai-chat.mjs
 *
 * The server runs on port 3456 by default (configurable via PORT env var).
 * The BlockEditor component should be configured with ai_url: 'http://localhost:3456/api/ai/chat'
 */

import { createServer } from 'node:http'
import { streamText, convertToModelMessages } from 'ai'
import { anthropic } from '@ai-sdk/anthropic'
import {
  aiDocumentFormats,
  injectDocumentStateMessages,
  toolDefinitionsToToolSet
} from '@blocknote/xl-ai/server'

const PORT = process.env.PORT || 3456
const MODEL = process.env.AI_MODEL || 'claude-sonnet-4-5-20250929'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type'
}

const server = createServer(async (req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, CORS_HEADERS)
    res.end()
    return
  }

  if (req.method !== 'POST' || req.url !== '/api/ai/chat') {
    res.writeHead(404, { 'Content-Type': 'text/plain', ...CORS_HEADERS })
    res.end('Not found')
    return
  }

  try {
    const body = await readBody(req)
    const { messages, toolDefinitions } = JSON.parse(body)

    const result = streamText({
      model: anthropic(MODEL),
      system: aiDocumentFormats.html.systemPrompt,
      messages: await convertToModelMessages(
        injectDocumentStateMessages(messages)
      ),
      tools: toolDefinitionsToToolSet(toolDefinitions),
      toolChoice: 'required'
    })

    const response = result.toUIMessageStreamResponse()

    // Forward the streaming response
    res.writeHead(response.status, {
      ...Object.fromEntries(response.headers.entries()),
      ...CORS_HEADERS
    })

    const reader = response.body.getReader()
    const pump = async () => {
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        res.write(value)
      }
      res.end()
    }
    await pump()
  } catch (error) {
    console.error('AI chat error:', error)
    if (!res.headersSent) {
      res.writeHead(500, { 'Content-Type': 'application/json', ...CORS_HEADERS })
      res.end(JSON.stringify({ error: error.message }))
    }
  }
})

function readBody (req) {
  return new Promise((resolve, reject) => {
    const chunks = []
    req.on('data', (chunk) => chunks.push(chunk))
    req.on('end', () => resolve(Buffer.concat(chunks).toString()))
    req.on('error', reject)
  })
}

server.listen(PORT, () => {
  console.log(`BlockEditor AI server running on http://localhost:${PORT}`)
  console.log(`Model: ${MODEL}`)
  console.log(`Endpoint: POST http://localhost:${PORT}/api/ai/chat`)
  console.log()
  console.log('Configure your BlockEditor with:')
  console.log(`  ai_url: 'http://localhost:${PORT}/api/ai/chat'`)
})
