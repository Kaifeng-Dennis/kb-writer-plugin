import assert from 'node:assert/strict';
import { test } from 'node:test';

import { APPROVED_CAPABILITY_NAMES, KbWriterClient } from '../dist/kb-writer-client.js';
import { TOOL_DEFINITIONS } from '../dist/index.js';

test('registers track_skill_usage with exactly three required attribution fields', () => {
  assert.ok(APPROVED_CAPABILITY_NAMES.includes('track_skill_usage'));
  const tool = TOOL_DEFINITIONS.find(({ name }) => name === 'track_skill_usage');
  assert.deepEqual(tool.inputSchema.required, ['skill_name', 'skill_version', 'source_app']);
  for (const field of tool.inputSchema.required) {
    assert.equal(tool.inputSchema.properties[field].type, 'string');
  }
});

test('posts one authenticated tracking call through backend MCP and unwraps its result', async () => {
  const requests = [];
  const client = new KbWriterClient({
    baseUrl: 'https://kb-writer.example.test/',
    accessToken: 'test-token',
    fetchImpl: async (url, init) => {
      requests.push({ url: String(url), init });
      return new Response(JSON.stringify({
        jsonrpc: '2.0',
        id: 1,
        result: { content: [{ type: 'text', text: '{"recorded":true}' }], structuredContent: { recorded: true } },
      }), { status: 200, headers: { 'content-type': 'application/json' } });
    },
  });

  const result = await client.callCapability('track_skill_usage', {
    skill_name: 'kb-ticket', skill_version: '0.3.0', source_app: 'codex',
  });

  assert.deepEqual(result, { recorded: true });
  assert.equal(requests.length, 1);
  assert.equal(requests[0].url, 'https://kb-writer.example.test/mcp');
  assert.equal(requests[0].init.method, 'POST');
  assert.equal(requests[0].init.headers.Authorization, 'Bearer test-token');
  assert.equal(requests[0].init.headers.Accept, 'application/json, text/event-stream');
  assert.deepEqual(JSON.parse(requests[0].init.body), {
    jsonrpc: '2.0', id: 1, method: 'tools/call',
    params: { name: 'track_skill_usage', arguments: {
      skill_name: 'kb-ticket', skill_version: '0.3.0', source_app: 'codex',
    } },
  });
});

test('rejects a backend MCP tool error instead of reporting a recorded event', async () => {
  const client = new KbWriterClient({
    baseUrl: 'https://kb-writer.example.test/',
    accessToken: 'test-token',
    fetchImpl: async () => new Response(JSON.stringify({
      jsonrpc: '2.0', id: 1,
      result: { isError: true, structuredContent: { code: 'HTTP_400', message: 'Unsupported skill' } },
    }), { status: 200, headers: { 'content-type': 'application/json' } }),
  });

  await assert.rejects(
    client.callCapability('track_skill_usage', {
      skill_name: 'unknown', skill_version: '0.3.0', source_app: 'codex',
    }),
    /Unsupported skill/,
  );
});

test('rejects a non-JSON success response for tracking', async () => {
  const client = new KbWriterClient({
    baseUrl: 'https://kb-writer.example.test/',
    accessToken: 'test-token',
    fetchImpl: async () => new Response('ok', { status: 200, headers: { 'content-type': 'text/plain' } }),
  });

  await assert.rejects(
    client.callCapability('track_skill_usage', {
      skill_name: 'kb-ticket', skill_version: '0.3.0', source_app: 'codex',
    }),
    /Invalid KB Writer MCP response/,
  );
});
