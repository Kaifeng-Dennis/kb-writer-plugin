#!/usr/bin/env node
import { createInterface } from 'node:readline';
import { pathToFileURL } from 'node:url';

import {
  APPROVED_CAPABILITY_NAMES,
  type ApprovedCapabilityName,
  type CapabilityArguments,
  type JsonValue,
  KbWriterBackendError,
  KbWriterClient,
} from './kb-writer-client.ts';
import { KB_WRITER_MCP_VERSION } from './version.ts';

type JsonRpcId = string | number | null;

interface JsonRpcRequest {
  jsonrpc: '2.0';
  id?: JsonRpcId;
  method: string;
  params?: Record<string, JsonValue>;
}

interface JsonRpcResponse {
  jsonrpc: '2.0';
  id: JsonRpcId;
  result?: unknown;
  error?: {
    code: number;
    message: string;
    data?: JsonValue;
  };
}

interface CapabilityCaller {
  callCapability(name: ApprovedCapabilityName, args: CapabilityArguments): Promise<JsonValue>;
  /** Version the backend currently ships, when it is newer than this one. */
  updateAvailable?: string | null;
  /** Where that version can be downloaded, on the configured backend. */
  updateDownloadUrl?: string | null;
  /** The plugin archive beside it, for installs that came from a file. */
  updatePluginUrl?: string | null;
}

interface ToolDefinition {
  name: ApprovedCapabilityName;
  description: string;
  inputSchema: {
    type: 'object';
    properties: Record<string, JsonValue>;
    required: string[];
    additionalProperties: true;
  };
}

const INTEGER_ARGUMENTS = new Set([
  'workspace_id', 'planning_job_id', 'draft_id', 'failed_planning_job_id',
  'expected_workspace_version', 'expected_manifest_id', 'preview_job_id',
  'original_manifest_id', 'work_item_id', 'current_manifest_id', 'expected_version',
  'expected_work_item_version', 'limit', 'cursor',
]);

const ARGUMENTS: Record<ApprovedCapabilityName, readonly [string[], string[]]> = {
  list_my_workspaces: [[], ['status', 'limit', 'cursor']],
  promote_ticket: [['jira_key'], []],
  resolve_workspace_by_jira_key: [['jira_key'], []],
  get_workspace: [['workspace_id'], []],
  get_planning_status: [['planning_job_id'], []],
  get_generation_manifest: [['workspace_id'], []],
  discover_article_targets: [['workspace_id'], ['manifest_item_key', 'query', 'limit']],
  get_article_target: [['workspace_id', 'article_id'], []],
  get_article_tasks: [['workspace_id'], []],
  get_latest_generation_status: [['workspace_id'], []],
  get_draft: [['draft_id'], []],
  list_publish_destinations: [['workspace_id'], []],
  create_intent_workspace: [['envelope', 'idempotency_key'], []],
  retry_intent_planning: [[
    'workspace_id', 'failed_planning_job_id', 'expected_workspace_version', 'idempotency_key',
  ], []],
  revise_intent_input: [['workspace_id', 'expected_workspace_version', 'envelope', 'idempotency_key'], []],
  resolve_article_target: [['workspace_id', 'reference', 'idempotency_key'], []],
  add_workspace_evidence: [[
    'workspace_id', 'expected_manifest_id', 'evidence', 'idempotency_key',
  ], []],
  remove_manifest_source: [[
    'workspace_id', 'expected_manifest_id', 'source_id', 'idempotency_key',
  ], []],
  replace_manifest_source: [[
    'workspace_id', 'expected_manifest_id', 'source_id', 'replacement_reference', 'idempotency_key',
  ], []],
  add_manifest_item: [['workspace_id', 'expected_manifest_id', 'item', 'idempotency_key'], []],
  edit_manifest_item: [[
    'workspace_id', 'expected_manifest_id', 'item_key', 'patch', 'idempotency_key',
  ], []],
  remove_manifest_item: [[
    'workspace_id', 'expected_manifest_id', 'item_key', 'idempotency_key',
  ], []],
  record_no_kb_change: [[
    'workspace_id', 'expected_manifest_id', 'reason', 'idempotency_key',
  ], []],
  select_update_target: [[
    'workspace_id', 'expected_manifest_id', 'item_key', 'article_id', 'target_snapshot_id',
    'idempotency_key',
  ], []],
  accept_manifest_risk: [[
    'workspace_id', 'expected_manifest_id', 'item_key', 'risk', 'idempotency_key',
  ], []],
  start_drafts: [[
    'workspace_id', 'expected_manifest_id', 'selected_item_keys', 'idempotency_key',
  ], []],
  resume_preview_job: [['preview_job_id', 'original_manifest_id', 'idempotency_key'], []],
  regenerate_with_manifest: [[
    'work_item_id', 'current_manifest_id', 'selected_item_key', 'idempotency_key',
  ], []],
  update_draft: [['draft_id', 'expected_version', 'content', 'idempotency_key'], []],
  assign_content_owner: [[
    'work_item_id', 'expected_work_item_version', 'owner_identity', 'idempotency_key',
  ], []],
  submit_draft_for_content_review: [[
    'work_item_id', 'expected_work_item_version', 'idempotency_key',
  ], ['content_owner_identity']],
  approve_content_for_publish: [[
    'work_item_id', 'expected_work_item_version', 'idempotency_key',
  ], []],
  return_content_to_pm_review: [[
    'work_item_id', 'expected_work_item_version', 'reason', 'idempotency_key',
  ], []],
  publish_draft: [[
    'draft_id', 'expected_version', 'destination_id', 'publication_input', 'idempotency_key',
  ], []],
  complete_workspace: [['workspace_id', 'expected_workspace_version', 'idempotency_key'], []],
  archive_workspace: [['workspace_id', 'expected_workspace_version', 'idempotency_key'], []],
};

export const TOOL_DEFINITIONS: ToolDefinition[] = APPROVED_CAPABILITY_NAMES.map((name) => {
  const [required, optional] = ARGUMENTS[name];
  return {
    name,
    description: `Delegate ${name} to the authenticated KB Writer HTTP capability without local domain state.`,
    inputSchema: {
      type: 'object',
      properties: Object.fromEntries([...required, ...optional].map((argument) => [
        argument,
        {
          description: `KB Writer ${argument} argument; values pass through unchanged.`,
          ...argumentSchema(argument),
        },
      ])),
      required: [...required],
      additionalProperties: true,
    },
  };
});

function argumentSchema(argument: string): Record<string, JsonValue> {
  if (INTEGER_ARGUMENTS.has(argument)) return { type: 'integer' };
  if (argument === 'reuse_previous_context') return { type: 'boolean' };
  if (argument === 'selected_item_keys') return { type: 'array', items: { type: 'string' } };
  return {};
}

export function createMcpRequestHandler(client: CapabilityCaller) {
  return async (request: JsonRpcRequest): Promise<Omit<JsonRpcResponse, 'jsonrpc' | 'id'> | null> => {
    switch (request.method) {
      case 'initialize': {
        const requestedVersion = request.params?.protocolVersion;
        return {
          result: {
            protocolVersion: typeof requestedVersion === 'string' ? requestedVersion : '2025-06-18',
            capabilities: { tools: {} },
            serverInfo: { name: 'kb-writer-mcp', version: KB_WRITER_MCP_VERSION },
          },
        };
      }
      case 'notifications/initialized':
      case 'notifications/cancelled':
        return null;
      case 'ping':
        return { result: {} };
      case 'tools/list':
        return { result: { tools: TOOL_DEFINITIONS } };
      case 'tools/call': {
        const name = request.params?.name;
        if (typeof name !== 'string' || !isApprovedCapabilityName(name)) {
          throw new McpRequestError(-32602, 'Unknown KB Writer tool');
        }
        const rawArguments = request.params?.arguments;
        const args = isObject(rawArguments) ? rawArguments : {};
        let result: JsonValue;
        try {
          result = await client.callCapability(name, args);
        } catch (error) {
          if (error instanceof KbWriterBackendError && isExpectedWorkflowFailure(error)) {
            return workflowFailure(
              error,
              client.updateAvailable ?? null,
              client.updateDownloadUrl ?? null,
              client.updatePluginUrl ?? null,
            );
          }
          throw error;
        }
        const structuredContent = isObject(result) ? { structuredContent: result } : {};
        const content: JsonValue[] = [{ type: 'text', text: JSON.stringify(result) }];
        // The extension installs outside the plugin, so nothing updates it on
        // the user's behalf and a stale one fails by missing tools the newer
        // skills call for. Say so in the result the model already reads.
        if (client.updateAvailable) {
          content.push({
            type: 'text',
            text: updateNotice(
              client.updateAvailable,
              client.updateDownloadUrl ?? null,
              client.updatePluginUrl ?? null,
            ),
          });
        }
        return {
          result: {
            content,
            ...structuredContent,
          },
        };
      }
      default:
        throw new McpRequestError(-32601, 'Method not found');
    }
  };
}

function updateNotice(
  availableVersion: string,
  downloadUrl: string | null,
  pluginUrl: string | null,
): string {
  // Carries the links rather than directions to them: the alternative is four
  // menus deep in another app, which nobody follows mid-task. Markdown, so a
  // relayed notice reads as two short names instead of two long URLs, and the
  // file name is the one to check against what actually downloads.
  const head =
    `KB Writer extension update: ${KB_WRITER_MCP_VERSION} installed, ` +
    `${availableVersion} available.`;
  if (!downloadUrl) return `${head} Run /kb-writer:setup.`;
  // Nothing here knows how the plugin itself was installed. One added from the
  // marketplace updates itself, so pointing every reader at the archive would
  // send most of them to redo something already done.
  const plugin = pluginUrl
    ? ` If the plugin was uploaded as a file rather than added from the marketplace, replace it from [kb-writer-plugin.zip](${pluginUrl}) too.`
    : '';
  return (
    `${head} Reinstall the extension from [kb-writer-mcp.mcpb](${downloadUrl}).` +
    `${plugin} /kb-writer:setup has the steps.`
  );
}


function workflowFailure(
  error: KbWriterBackendError,
  updateAvailable: string | null,
  updateDownloadUrl: string | null,
  updatePluginUrl: string | null,
): { result: JsonValue } {
  const backend = isObject(error.details) ? error.details : {};
  const code = typeof backend.code === 'string' ? backend.code : `HTTP_${error.status}`;
  const message = typeof backend.message === 'string' ? backend.message : error.message;
  const nextAction = workflowNextAction(code, error.status);
  const structuredContent = { code, message, next_action: nextAction };
  const content: JsonValue[] = [{ type: 'text', text: JSON.stringify(structuredContent) }];
  // A stale extension calling a capability the backend has since changed is
  // one of the likelier reasons to be here, so this is exactly when the
  // reader needs to know an update exists.
  if (updateAvailable) {
    content.push({
      type: 'text',
      text: updateNotice(updateAvailable, updateDownloadUrl, updatePluginUrl),
    });
  }
  return {
    result: {
      content,
      structuredContent,
      isError: true,
    },
  };
}

function workflowNextAction(code: string, status: number): string {
  if (code === 'CONTENT_OWNER_REQUIRED') return 'Choose a content owner, then submit again.';
  if (code === 'VERSION_CONFLICT' || status === 409) return 'Refresh the current item, then retry.';
  if (status === 401) return 'Reconnect KB Writer, then retry.';
  if (status === 403) return 'Use an identity that is allowed to perform this action.';
  if (status === 404) return 'Refresh the current ticket or workspace before retrying.';
  return 'Resolve the reported condition, then retry.';
}

function isExpectedWorkflowFailure(error: KbWriterBackendError): boolean {
  if ([401, 403, 404, 409, 422].includes(error.status)) return true;
  const backend = isObject(error.details) ? error.details : {};
  return backend.code === 'CONTENT_OWNER_REQUIRED' || backend.code === 'VERSION_CONFLICT';
}

class McpRequestError extends Error {
  readonly code: number;

  constructor(code: number, message: string) {
    super(message);
    this.code = code;
  }
}

async function serveStdio(): Promise<void> {
  const baseUrl = process.env.KB_WRITER_API_BASE_URL ?? 'https://kb-companion.int.rclabenv.com';
  const accessToken = process.env.KB_WRITER_ACCESS_TOKEN;
  if (!accessToken) {
    throw new Error(
      'KB_WRITER_ACCESS_TOKEN is not set. Run the kb-writer:setup skill to sign in and configure it.',
    );
  }
  const handler = createMcpRequestHandler(new KbWriterClient({ baseUrl, accessToken }));
  const lines = createInterface({ input: process.stdin, crlfDelay: Infinity });
  for await (const line of lines) {
    if (!line.trim()) continue;
    let request: JsonRpcRequest;
    try {
      request = JSON.parse(line) as JsonRpcRequest;
    } catch {
      writeResponse({
        jsonrpc: '2.0',
        id: null,
        error: { code: -32700, message: 'Parse error' },
      });
      continue;
    }
    try {
      const handled = await handler(request);
      if (handled !== null && request.id !== undefined) {
        writeResponse({ jsonrpc: '2.0', id: request.id, ...handled });
      }
    } catch (error) {
      if (request.id === undefined) continue;
      writeResponse(errorResponse(request.id, error));
    }
  }
}

function errorResponse(id: JsonRpcId, error: unknown): JsonRpcResponse {
  if (error instanceof KbWriterBackendError) {
    return {
      jsonrpc: '2.0',
      id,
      error: {
        code: -32000,
        message: error.message,
        data: { httpStatus: error.status, backend: error.details },
      },
    };
  }
  if (error instanceof McpRequestError) {
    return { jsonrpc: '2.0', id, error: { code: error.code, message: error.message } };
  }
  const message = error instanceof Error ? error.message : 'KB Writer MCP request failed';
  return { jsonrpc: '2.0', id, error: { code: -32603, message } };
}

function writeResponse(response: JsonRpcResponse): void {
  process.stdout.write(`${JSON.stringify(response)}\n`);
}

function isApprovedCapabilityName(value: string): value is ApprovedCapabilityName {
  return (APPROVED_CAPABILITY_NAMES as readonly string[]).includes(value);
}

function isObject(value: unknown): value is CapabilityArguments {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

const invokedPath = process.argv[1] ? pathToFileURL(process.argv[1]).href : '';
if (import.meta.url === invokedPath) {
  serveStdio().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : 'KB Writer MCP failed to start';
    process.stderr.write(`${message}\n`);
    process.exitCode = 1;
  });
}
