#!/usr/bin/env node
import { createInterface } from 'node:readline';
import { pathToFileURL } from 'node:url';
import { APPROVED_CAPABILITY_NAMES, KbWriterBackendError, KbWriterClient, } from "./kb-writer-client.js";
const ARGUMENTS = {
    list_my_workspaces: [[], ['status', 'limit', 'cursor']],
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
        ], []],
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
export const TOOL_DEFINITIONS = APPROVED_CAPABILITY_NAMES.map((name) => {
    const [required, optional] = ARGUMENTS[name];
    return {
        name,
        description: `Delegate ${name} to the authenticated KB Writer HTTP capability without local domain state.`,
        inputSchema: {
            type: 'object',
            properties: Object.fromEntries([...required, ...optional].map((argument) => [
                argument,
                { description: `KB Writer ${argument} argument; values pass through unchanged.` },
            ])),
            required: [...required],
            additionalProperties: true,
        },
    };
});
export function createMcpRequestHandler(client) {
    return async (request) => {
        switch (request.method) {
            case 'initialize': {
                const requestedVersion = request.params?.protocolVersion;
                return {
                    result: {
                        protocolVersion: typeof requestedVersion === 'string' ? requestedVersion : '2025-06-18',
                        capabilities: { tools: {} },
                        serverInfo: { name: 'kb-writer-mcp', version: '0.1.0' },
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
                const result = await client.callCapability(name, args);
                const structuredContent = isObject(result) ? { structuredContent: result } : {};
                return {
                    result: {
                        content: [{ type: 'text', text: JSON.stringify(result) }],
                        ...structuredContent,
                    },
                };
            }
            default:
                throw new McpRequestError(-32601, 'Method not found');
        }
    };
}
class McpRequestError extends Error {
    code;
    constructor(code, message) {
        super(message);
        this.code = code;
    }
}
async function serveStdio() {
    const baseUrl = process.env.KB_WRITER_API_BASE_URL ?? 'https://kb-companion.int.rclabenv.com';
    const accessToken = process.env.KB_WRITER_ACCESS_TOKEN;
    if (!accessToken) {
        throw new Error('KB_WRITER_ACCESS_TOKEN is not set. Run the kb-writer:setup skill to sign in and configure it.');
    }
    const handler = createMcpRequestHandler(new KbWriterClient({ baseUrl, accessToken }));
    const lines = createInterface({ input: process.stdin, crlfDelay: Infinity });
    for await (const line of lines) {
        if (!line.trim())
            continue;
        let request;
        try {
            request = JSON.parse(line);
        }
        catch {
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
        }
        catch (error) {
            if (request.id === undefined)
                continue;
            writeResponse(errorResponse(request.id, error));
        }
    }
}
function errorResponse(id, error) {
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
function writeResponse(response) {
    process.stdout.write(`${JSON.stringify(response)}\n`);
}
function isApprovedCapabilityName(value) {
    return APPROVED_CAPABILITY_NAMES.includes(value);
}
function isObject(value) {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
}
const invokedPath = process.argv[1] ? pathToFileURL(process.argv[1]).href : '';
if (import.meta.url === invokedPath) {
    serveStdio().catch((error) => {
        const message = error instanceof Error ? error.message : 'KB Writer MCP failed to start';
        process.stderr.write(`${message}\n`);
        process.exitCode = 1;
    });
}
