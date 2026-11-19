# Project Instructions
- Writing: keep user's voice, conversational, stick closely to what user said without making things up, but fix small grammar mistakes
- After adding or renaming tips, run `node scripts/generate-toc.js` to update the table of contents
- `~/.claude/CLAUDE.md` is symlinked to `GLOBAL-CLAUDE.md` in this repo
- When committing changes to the plugin (skills, plugin.json, etc.), bump the patch version in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Don't bump for non-plugin changes like system prompt patches.
- Git tags/releases (e.g. `v0.25.1`) and plugin versions (e.g. `0.14.9`) are separate. The git tag follows the repo release progression and is bumped for any change. The plugin version is only in `plugin.json` and `marketplace.json`.

## Installing a specific native binary version

Native binaries are on GCS, not GitHub releases. To install a specific version:

1. Fetch the manifest: `curl -sL "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/{VERSION}/manifest.json"`
2. Download the binary (use a safeclaw container): `.../claude-code-releases/{VERSION}/{PLATFORM}/claude` where PLATFORM is `darwin-arm64`, `linux-arm64`, etc.
3. Verify SHA256 checksum against the manifest
4. Place at `~/.local/share/claude/versions/{VERSION}` and `chmod 755`
5. Update symlink: `ln -sf ~/.local/share/claude/versions/{VERSION} ~/.local/bin/claude`
6. Patch with `bash system-prompt/{VERSION}/patch-native.sh`

## Fleet guardrails

Conformance canary: **CANARY-GUARDRAILS-V1**.

27. **SURGICAL CHANGES (Karpathy, CEO 2026-11-18).** When editing existing code, every changed line
    traces to the request; remove only orphans your change created. Never "improve", refactor or
    reformat adjacent code, and never delete dead code you did not create: mention it instead.
    Refs:
    1. /central-command/policies-procedures/compliance/policies/GUARDRAILS.md (44 Surgical changes)

28. **AGENTS.MD IS THE ONLY HAND-EDITED AGENT FILE (CEO 2026-11-18).** Edit only the repo-root
    `AGENTS.md`, only on a branch named `agents-md-update-<triggering-branch-slug>` (central-command
    off `dev`, other repos off `main`); `bash scripts/agents-md-guard.sh sync` then writes the copies
    (`QWEN.md`, `WARP.md`, `.clinerules/`, copilot, `GEMINI.md`) and the `CLAUDE.md` stub. Never
    hand-edit a copy. Any other branch touching these files: STOP-severity, CI `agents-md-guard` fails.
    Refs:
    1. /central-command/policies-procedures/compliance/policies/GUARDRAILS.md (45 AGENTS.md is the only hand-edited agent file)
    2. /central-command/scripts/agents-md-guard.sh
    3. /central-command/policies-procedures/operations/procedures/PROJECT-SCAFFOLDING.md

29. **CENTRAL-COMMAND POLICY MIRROR (CEO 2026-11-19).** Every repo root carries
    `central-command/policies-procedures/` = the pull of central-command DEV's
    `policies-procedures/` folder (policy DATA); Refs written
    `/central-command/policies-procedures/...` resolve there. An hourly workflow on the
    repo's local ARC runner (`NONE-MEASURED` — this repo has no ARC scale set yet,
    tracked as [#2445](https://github.com/gitjfmd/K8-main-boss/issues/2445)) refreshes it
    from central-command `dev` by immutable-SHA fetch and commits only when content
    differs, using the read-only PAT `CENTRAL_COMMAND_READ_PAT` (name only; never print
    it, never pass it in argv). Never hand-edit the mirror; on demand run
    `scripts/sync-central-policy.sh` (`--dry-run` reports whether the folder is current).
    Refs:
    1. /central-command/policies-procedures/operations/procedures/CENTRAL-POLICY-SYNC.md
