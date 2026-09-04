export const APPROVED_CAPABILITY_NAMES = [
    'list_my_workspaces',
    'resolve_workspace_by_jira_key',
    'get_workspace',
    'get_planning_status',
    'get_generation_manifest',
    'discover_article_targets',
    'get_article_target',
    'get_article_tasks',
    'get_latest_generation_status',
    'get_draft',
    'list_publish_destinations',
    'create_intent_workspace',
    'retry_intent_planning',
    'revise_intent_input',
    'resolve_article_target',
    'add_workspace_evidence',
    'remove_manifest_source',
    'replace_manifest_source',
    'add_manifest_item',
    'edit_manifest_item',
    'remove_manifest_item',
    'record_no_kb_change',
    'select_update_target',
    'accept_manifest_risk',
    'start_drafts',
    'resume_preview_job',
    'regenerate_with_manifest',
    'update_draft',
    'assign_content_owner',
    'submit_draft_for_content_review',
    'approve_content_for_publish',
    'return_content_to_pm_review',
    'publish_draft',
    'complete_workspace',
    'archive_workspace',
];
export class KbWriterBackendError extends Error {
    status;
    details;
    constructor(status, details) {
        const safeMessage = isJsonObject(details) && typeof details.message === 'string'
            ? details.message
            : `KB Writer request failed with HTTP ${status}`;
        super(safeMessage);
        this.name = 'KbWriterBackendError';
        this.status = status;
        this.details = details;
    }
}
export class KbWriterClient {
    baseUrl;
    accessToken;
    fetchImpl;
    constructor(options) {
        const parsedBaseUrl = new URL(options.baseUrl);
        if (parsedBaseUrl.username || parsedBaseUrl.password) {
            throw new Error('KB Writer base URL must not contain credentials');
        }
        this.baseUrl = parsedBaseUrl.toString().replace(/\/$/, '');
        this.accessToken = options.accessToken;
        this.fetchImpl = options.fetchImpl ?? fetch;
    }
    async callCapability(name, args) {
        const spec = requestSpec(name, args);
        const url = new URL(`${this.baseUrl}${spec.path}`);
        if (spec.query)
            url.search = spec.query.toString();
        const headers = {
            Authorization: `Bearer ${this.accessToken}`,
            Accept: 'application/json',
        };
        const init = { method: spec.method, headers };
        if (spec.body !== undefined) {
            headers['Content-Type'] = 'application/json';
            init.body = JSON.stringify(spec.body);
        }
        if (spec.idempotencyKey !== undefined) {
            headers['Idempotency-Key'] = String(spec.idempotencyKey);
        }
        const response = await this.fetchImpl(url, init);
        if (!response.ok)
            throw await backendError(response);
        if (response.status === 204)
            return null;
        const contentType = response.headers.get('content-type') ?? '';
        if (!contentType.toLowerCase().includes('application/json'))
            return null;
        return await response.json();
    }
}
function requestSpec(name, args) {
    const workspacePath = () => `/v1/intent-workspaces/${segment(required(args, 'workspace_id'))}`;
    const taskPath = () => `/v1/intent-workspaces/tasks/${segment(required(args, 'work_item_id'))}`;
    const draftPath = () => `/v1/intent-workspaces/drafts/${segment(required(args, 'draft_id'))}`;
    const idempotencyKey = () => required(args, 'idempotency_key');
    switch (name) {
        case 'list_my_workspaces':
            return {
                method: 'GET',
                path: '/v1/intent-workspaces',
                query: queryParams(args, [
                    ['status', 'status'],
                    ['limit', 'limit'],
                    ['cursor', 'cursor'],
                ]),
            };
        case 'resolve_workspace_by_jira_key':
            return { method: 'GET', path: `/v1/intent-workspaces/resolve/jira/${segment(required(args, 'jira_key'))}` };
        case 'get_workspace':
            return { method: 'GET', path: workspacePath() };
        case 'get_planning_status':
            return {
                method: 'GET',
                path: `/v1/intent-workspaces/planning-jobs/${segment(required(args, 'planning_job_id'))}`,
            };
        case 'get_generation_manifest':
            return { method: 'GET', path: `${workspacePath()}/manifest` };
        case 'discover_article_targets':
            return {
                method: 'GET',
                path: `${workspacePath()}/targets`,
                query: queryParams(args, [
                    ['manifest_item_key', 'manifestItemKey'],
                    ['query', 'query'],
                    ['limit', 'limit'],
                ]),
            };
        case 'get_article_target':
            return {
                method: 'GET',
                path: `${workspacePath()}/targets/${segment(required(args, 'article_id'))}`,
            };
        case 'get_article_tasks':
            return { method: 'GET', path: `${workspacePath()}/tasks` };
        case 'get_latest_generation_status':
            return { method: 'GET', path: `${workspacePath()}/generation/latest` };
        case 'get_draft':
            return { method: 'GET', path: draftPath() };
        case 'list_publish_destinations':
            return { method: 'GET', path: `${workspacePath()}/publish-destinations` };
        case 'create_intent_workspace':
            return {
                method: 'POST',
                path: '/v1/intent-workspaces',
                body: required(args, 'envelope'),
                idempotencyKey: idempotencyKey(),
            };
        case 'retry_intent_planning':
            return post(`${workspacePath()}/planning/retry`, {
                failedPlanningJobId: required(args, 'failed_planning_job_id'),
                expectedWorkspaceVersion: required(args, 'expected_workspace_version'),
            }, idempotencyKey());
        case 'revise_intent_input':
            return post(`${workspacePath()}/planning/revise`, {
                expectedWorkspaceVersion: required(args, 'expected_workspace_version'),
                envelope: required(args, 'envelope'),
            }, idempotencyKey());
        case 'resolve_article_target':
            return post(`${workspacePath()}/targets/resolve`, {
                reference: required(args, 'reference'),
            }, idempotencyKey());
        case 'add_workspace_evidence':
            return post(`${workspacePath()}/manifest/evidence`, {
                expectedManifestId: required(args, 'expected_manifest_id'),
                evidence: required(args, 'evidence'),
            }, idempotencyKey());
        case 'remove_manifest_source':
            return post(`${workspacePath()}/manifest/sources/${segment(required(args, 'source_id'))}/remove`, { expectedManifestId: required(args, 'expected_manifest_id') }, idempotencyKey());
        case 'replace_manifest_source':
            return post(`${workspacePath()}/manifest/sources/${segment(required(args, 'source_id'))}/replace`, {
                expectedManifestId: required(args, 'expected_manifest_id'),
                replacementReference: required(args, 'replacement_reference'),
            }, idempotencyKey());
        case 'add_manifest_item':
            return post(`${workspacePath()}/manifest/items`, {
                expectedManifestId: required(args, 'expected_manifest_id'),
                ...requiredObject(args, 'item'),
            }, idempotencyKey());
        case 'edit_manifest_item':
            return {
                method: 'PATCH',
                path: `${workspacePath()}/manifest/items/${segment(required(args, 'item_key'))}`,
                body: {
                    expectedManifestId: required(args, 'expected_manifest_id'),
                    ...requiredObject(args, 'patch'),
                },
                idempotencyKey: idempotencyKey(),
            };
        case 'remove_manifest_item':
            return post(`${workspacePath()}/manifest/items/${segment(required(args, 'item_key'))}/remove`, { expectedManifestId: required(args, 'expected_manifest_id') }, idempotencyKey());
        case 'record_no_kb_change':
            return post(`${workspacePath()}/manifest/no-kb-change`, {
                expectedManifestId: required(args, 'expected_manifest_id'),
                reason: required(args, 'reason'),
            }, idempotencyKey());
        case 'select_update_target':
            return post(`${workspacePath()}/manifest/items/${segment(required(args, 'item_key'))}/select-target`, {
                expectedManifestId: required(args, 'expected_manifest_id'),
                articleId: required(args, 'article_id'),
                targetSnapshotId: required(args, 'target_snapshot_id'),
            }, idempotencyKey());
        case 'accept_manifest_risk':
            return post(`${workspacePath()}/manifest/items/${segment(required(args, 'item_key'))}/accept-risk`, {
                expectedManifestId: required(args, 'expected_manifest_id'),
                ...requiredObject(args, 'risk'),
            }, idempotencyKey());
        case 'start_drafts':
            return post(`${workspacePath()}/manifest/start-drafts`, {
                expectedManifestId: required(args, 'expected_manifest_id'),
                selectedItemKeys: required(args, 'selected_item_keys'),
            }, idempotencyKey());
        case 'resume_preview_job':
            return post(`/v1/intent-workspaces/preview-jobs/${segment(required(args, 'preview_job_id'))}/resume`, { originalManifestId: required(args, 'original_manifest_id') }, idempotencyKey());
        case 'regenerate_with_manifest':
            return post(`${taskPath()}/regenerate-with-manifest`, {
                currentManifestId: required(args, 'current_manifest_id'),
                selectedItemKey: required(args, 'selected_item_key'),
            }, idempotencyKey());
        case 'update_draft':
            return {
                method: 'PATCH',
                path: draftPath(),
                body: {
                    expectedVersion: required(args, 'expected_version'),
                    content: required(args, 'content'),
                },
                idempotencyKey: idempotencyKey(),
            };
        case 'assign_content_owner':
            return post(`${taskPath()}/assign-content-owner`, {
                expectedWorkItemVersion: required(args, 'expected_work_item_version'),
                ownerIdentity: required(args, 'owner_identity'),
            }, idempotencyKey());
        case 'submit_draft_for_content_review':
            return post(`${taskPath()}/submit-content-review`, {
                expectedWorkItemVersion: required(args, 'expected_work_item_version'),
            }, idempotencyKey());
        case 'approve_content_for_publish':
            return post(`${taskPath()}/approve-content-for-publish`, {
                expectedWorkItemVersion: required(args, 'expected_work_item_version'),
            }, idempotencyKey());
        case 'return_content_to_pm_review':
            return post(`${taskPath()}/return-to-pm-review`, {
                expectedWorkItemVersion: required(args, 'expected_work_item_version'),
                reason: required(args, 'reason'),
            }, idempotencyKey());
        case 'publish_draft':
            return post(`${draftPath()}/publish`, {
                expectedVersion: required(args, 'expected_version'),
                destinationId: required(args, 'destination_id'),
                publicationInput: required(args, 'publication_input'),
            }, idempotencyKey());
        case 'complete_workspace':
            return post(`${workspacePath()}/complete`, {
                expectedWorkspaceVersion: required(args, 'expected_workspace_version'),
            }, idempotencyKey());
        case 'archive_workspace':
            return post(`${workspacePath()}/archive`, {
                expectedWorkspaceVersion: required(args, 'expected_workspace_version'),
            }, idempotencyKey());
    }
}
function post(path, body, idempotencyKey) {
    return { method: 'POST', path, body, idempotencyKey };
}
function required(args, key) {
    const value = args[key];
    if (value === undefined)
        throw new Error(`Missing required tool argument: ${key}`);
    return value;
}
function requiredObject(args, key) {
    const value = required(args, key);
    if (!isJsonObject(value))
        throw new Error(`Tool argument ${key} must be an object`);
    return value;
}
function segment(value) {
    if (typeof value !== 'string' && typeof value !== 'number') {
        throw new Error('Path identity must be a string or number');
    }
    return encodeURIComponent(String(value));
}
function queryParams(args, mappings) {
    const params = new URLSearchParams();
    for (const [argumentName, queryName] of mappings) {
        const value = args[argumentName];
        if (value !== undefined && value !== null)
            params.set(queryName, String(value));
    }
    return params;
}
async function backendError(response) {
    const contentType = response.headers.get('content-type') ?? '';
    if (!contentType.toLowerCase().includes('application/json')) {
        return new KbWriterBackendError(response.status, null);
    }
    const parsed = await response.json().catch(() => null);
    return new KbWriterBackendError(response.status, isJsonValue(parsed) ? parsed : null);
}
function isJsonObject(value) {
    return typeof value === 'object' && value !== null && !Array.isArray(value)
        && Object.values(value).every(isJsonValue);
}
function isJsonValue(value) {
    if (value === null || ['string', 'number', 'boolean'].includes(typeof value))
        return true;
    if (Array.isArray(value))
        return value.every(isJsonValue);
    return isJsonObject(value);
}
