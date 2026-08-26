---
name: testit-features
description: Use when fetching, searching, inspecting, or summarizing Jenkins artifact .feature files from testit-to-kb-daily-sync project folders.
---

# Jenkins Artifact Features

Use this skill to look up Jenkins artifact `.feature` knowledge without calling the TestIt API or querying the TestIt platform. Prefer remote lookup against the latest Jenkins artifact `knowledge_base.md`; only fetch a single `.feature` file when full scenario steps are needed.

## Source

Default artifact root:

```text
https://ci-jenkins.int.rclabenv.com/view/MQA/job/testit-to-kb-daily-sync/lastSuccessfulBuild/artifact/features
```

Use `--project <artifact-project-folder>` to select the Jenkins artifact project directory. If the user already supplied an artifact folder, use it directly. If they supplied a PM-facing project name, resolve it through the project registry flow below.

## Project Registry

For PM-facing project names, request `GET https://agent-cli-platform.int.rclabenv.com/api/pm-toolkit/projects` with a 5-second timeout and one retry. Accept only `schema_version: 1`, match `project_id` or `aliases` exactly after case normalization, and use `testit_project` as the artifact folder only when `testit_supported` is true.

If the registry request fails, use `references/project-registry-fallback.json` from the installed package; in a source checkout use `skills/_shared/project-registry-fallback.json`. State that fallback TestIt mappings may be stale. If the project is absent or TestIt is unsupported, do not guess a folder and report that automated artifact evidence is unavailable. Never maintain an artifact mapping table in this skill.

## Commands

Run commands from this skill directory:

```bash
python3 scripts/testit-features remote-search --project <artifact-project-folder> "accept queue"
python3 scripts/testit-features impact-candidates --project <artifact-project-folder> "accept queue"
python3 scripts/testit-features coverage-matrix --project air --project nova --theme "Public QA=public QA" --theme "Public search API=public search API|POST Search"
python3 scripts/testit-features case --project <artifact-project-folder> CASE-4160
python3 scripts/testit-features remote-show --project <artifact-project-folder> accept_queue_call.feature
```

Useful options:

```bash
python3 scripts/testit-features remote-search --project <artifact-project-folder> --max 10 "STORY-12294"
python3 scripts/testit-features impact-candidates --project <artifact-project-folder> --max 10 "fallback state"
python3 scripts/testit-features coverage-matrix --project air --project nova --theme "Predefined QA=predefined QA" --theme "Private QA skill=private QA skill" --fetch-full --full-candidate-max 2
python3 scripts/testit-features case --project <artifact-project-folder> --full CASE-4160
python3 scripts/testit-features remote-show --project <artifact-project-folder> --line 1 120 accept_queue_call
python3 scripts/testit-features remote-stats --project <artifact-project-folder>
```

Offline cache commands are available only when explicitly needed:

```bash
python3 scripts/testit-features sync --project <artifact-project-folder>
python3 scripts/testit-features search-cache --project <artifact-project-folder> "accept queue"
python3 scripts/testit-features show-cache --project <artifact-project-folder> accept_queue_call.feature
```

## Workflow

1. Use `remote-search` for feature names, case IDs, external IDs, Jira IDs, user stories, and scenario text. This reads the latest `knowledge_base.md` from Jenkins into memory and does not write all feature files locally.
2. Use `impact-candidates` when PM workflows need structured related case candidates for case impact analysis. This returns JSON with case IDs, related feature files, matched lines, scenario summary, and source context.
3. Use `coverage-matrix` when comparing multiple projects or multiple coverage themes. Pass explicit theme terms with `--theme "Theme name=term1|term2"`; do not hard-code domain synonyms inside the answer. If you add term variants from PM context, make them visible in `searched_terms`.
4. Use `case` for a specific case ID such as `CASE-4160`. Add `--full` only when full steps and validation points are needed; that fetches just the related `.feature` file.
5. Use `remote-show` only when the user names a feature file and wants to inspect it.
6. Include source context in answers: project, Jenkins `lastSuccessfulBuild`, related feature file, and whether full scenario detail was fetched.
7. For partial/closest-match conclusions, fetch full scenario detail for the top 1-2 related feature files before finalizing when practical. Use `coverage-matrix --fetch-full --full-candidate-max 2`, `case --full`, or `remote-show`.

## Cache

Offline cache commands write under:

```text
~/.cache/aidesk/testit-features/
```

Override with:

```bash
TESTIT_FEATURES_CACHE=/path/to/cache python3 scripts/testit-features sync --project <artifact-project-folder>
```

Do not use cache commands unless the user explicitly wants offline/local copies or repeated bulk searching.

## Reporting

When summarizing results, lead with the coverage signal:

- searched terms, matched terms, and no-match terms for each theme
- confidence per project/theme
- matching case IDs
- related feature file
- goal, user story, and priority when present
- structured impact candidates when the caller needs affected-case analysis
- full scenario steps only when fetched with `case --full` or `remote-show`

If Jenkins is unreachable and cached files exist, ask whether to answer from cache with lower freshness confidence.
