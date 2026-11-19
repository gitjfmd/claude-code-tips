---
summary: "The central-command policies-procedures mirror every repo root carries: hourly ARC pull of central-command dev by immutable SHA, local refresh script, read-only PAT. Serves every agent resolving /central-command/policies-procedures Refs."

id: "operations.procedures.central-policy-sync"
version: "1.0.0"
status: "active"
type: "procedure"
owner: "CEO"
reviewers: ["CEO"]
review_cadence: "quarterly"
last_reviewed: "2026-11-19"
next_review: "2027-02-19"
frameworks: []
evidence_basis: "CEO message 2026-11-19 (verbatim below) commissioning the mirror and the hourly workflow; this repo's runner label is NONE-MEASURED: no CI_RUNNER var and no ARC scale set exist here (measured 2026-11-19, 21 AutoscalingRunnerSets in ns arc-runners, none for this repo; a repo-specific scale set is tracked as K8-main-boss#2445)."
risk_addressed: "Policy drift across repos (each repo reading a stale or forked copy of the rules) and a torn pull from a moving dev ref."
completeness: 0.9
gaps: ["Rollout to consumer repos (copy the workflow + script, add the CENTRAL_COMMAND_READ_PAT secret) is not done by this doc."]
relations:
  enforces: []
  extends: []
  integrates_with: ["operations.procedures.PROJECT-SCAFFOLDING"]
applies_to: ["shared"]
project: "central-command"
date: "2026-11-19"
---

# Central Policy Sync

The central-command policies-procedures mirror every repo root carries: hourly ARC pull of central-command dev by immutable SHA, local refresh script, read-only PAT. Serves every agent resolving /central-command/policies-procedures Refs.

## The path

Every repo root carries `central-command/policies-procedures/` = a pull of central-command DEV's `policies-procedures/` folder. It is policy DATA, not an agent file. AGENTS.md Refs written as `/central-command/policies-procedures/...` resolve there. Never edit the mirror by hand: edit central-command and let the pull carry the change. The folder is replaced wholesale on each sync, so a file deleted upstream disappears from the mirror too.

## The hourly job

`.github/workflows/central-policy-sync.yml` runs at `17 * * * *` (hourly, off the :00 marks) plus `workflow_dispatch`, on the repo's local ARC runner label `NONE-MEASURED` (no repo ARC scale set exists yet, tracked as K8-main-boss#2445; literal, no vars fallback, so the job can never silently land on a hosted runner). It commits to the repo's default branch ONLY when content differs, with message `chore(policy-sync): central-command policies-procedures <sha>` and a provenance record in the body. No commit when unchanged, so there is no hourly noise. It NEVER runs on `pull_request`, and no pull_request job ever sees the PAT. A concurrency group stops two hourly runs from overlapping.

## The local script

`scripts/sync-central-policy.sh` performs the same pull on demand, in any checkout:

```bash
CENTRAL_COMMAND_READ_PAT=<read-only PAT> bash scripts/sync-central-policy.sh            # update the mirror
CENTRAL_COMMAND_READ_PAT=<read-only PAT> bash scripts/sync-central-policy.sh --dry-run  # report: current or DIFFERS
```

`--dry-run` exits 0 when the folder is current and 1 when it differs (or is missing) and writes nothing. An optional second argument overrides the destination root (default: the repo root's `central-command/`).

## The PAT

The secret is named **`CENTRAL_COMMAND_READ_PAT`**: a READ-ONLY PAT for `gitjfmd/central-command`, stored as a repo Actions secret (and mirrored per VAULT-FIRST SECRETS). Only the name appears in code and docs; the value is never printed, never logged, never passed in argv (argv is visible in `ps`), and never used in a `pull_request` job. It travels as an auth header so a git error message cannot print it inside a remote URL.

## The immutable-SHA rule

The pull resolves `dev` to its commit SHA first (`git ls-remote`), then fetches THAT SHA and extracts with `git archive FETCH_HEAD policies-procedures | tar -x`. A ref move in the middle of the pull therefore cannot produce a torn tree: the extract always corresponds to one commit. No submodules ride along (`git archive` excludes them) and a symlink in the extracted tree that resolves outside it fails the sync.

```yaml
provenance_record:
  recorded_at: "2026-11-19T06:55:00Z"
  cli: "claude"
  session_id: "a465de2e-c76f-4644-b964-8e806b392148"
  session_name: "central-command lean session"
  session_jsonl: "/Users/intelmedica/.claude/projects/-Users-intelmedica-Documents-mac-lab-central-command/a465de2e-c76f-4644-b964-8e806b392148.jsonl"
  ceo_message: >-
    repo/central-command in each repo root should be the dev brnach pulll of the folder policies&procedures. I wans very clear. an dthis can be done via an hourlyworkflow on runner or it runners with the readonly pat for central command
  branch: "agents-md-update-policy-sync"
  agents:
    - id: "agent-a472f0ee84f7091bc"
      cli: "claude"
      session_id: "20261119T004223-92232"
      jsonl: "/Users/intelmedica/.claude/projects/-Users-intelmedica-Documents-mac-lab-central-command/a465de2e-c76f-4644-b964-8e806b392148/subagents/workflows/wf_6220637f-b35/agent-a472f0ee84f7091bc.jsonl"
```
