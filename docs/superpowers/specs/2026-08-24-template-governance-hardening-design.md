# AI Project Template v1.1 Governance Hardening Design

- Status: Proposed
- Issue: [#1](https://github.com/alclssna33/ai-project-template/issues/1)
- Base main SHA: `56a2abcc0225a74f71d6fc7886aedcfb7e2ddd17`
- Policy version target: `1.1.0`

## 1. Purpose

`ai-project-template` is the central starting point for projects where Codex, ChatGPT, Claude Code, other AI agents, and people collaborate through isolated branches and worktrees. Version 1.1 will make the repository's bootstrap and policy checks enforce the safety rules already described in its documentation, then align the GitHub repository settings with those rules.

The result should let a new project begin from a known policy version, reject unsafe initialization contexts, validate the same policy invariants on Windows and Ubuntu, and use GitHub settings to prevent direct or destructive changes to `main`.

## 2. Scope

### In scope

- Mark the central repository as a GitHub template.
- Allow squash merges only and automatically delete merged head branches.
- Harden `scripts/initialize-project.ps1` so it rejects unsafe Git state before writing.
- Add repository line-ending rules.
- Make the PowerShell and Bash policy checkers enforce the same required files and policy invariants.
- Run both policy checkers in GitHub Actions.
- Update documentation, bootstrap prompt, and policy version to `1.1.0`.
- After the v1.1 workflow has passed on `main`, add a `main` ruleset that requires pull requests and the new required checks, resolves conversations, and blocks deletion and force pushes.

### Out of scope

- Automatic policy synchronization PRs across downstream repositories.
- A second Bash or Python project initializer.
- Application-language test, lint, typecheck, or build commands for projects created from the template.
- Automatic merge of this policy change.

Automatic downstream synchronization and a cross-platform initializer remain candidates for a later policy version after the v1.1 bootstrap is exercised by at least one real project.

## 3. Considered approaches

### A. Repository settings only

Enable template and branch protection settings without changing files. This is fast, but it leaves the initializer able to edit the default branch or accept a mismatched repository identity. It also leaves Windows and Ubuntu policy checks free to drift.

### B. Phased repository and policy hardening — selected

First update and validate the tracked policy, scripts, and CI through a Draft PR. After that PR is reviewed and merged, wait for the new checks to succeed on `main`, then apply the final required-check ruleset. This keeps file changes reviewable and avoids requiring check names that do not yet exist.

### C. Full governance automation now

Add cross-platform initialization and automatically open version-sync PRs in every downstream project. This provides the most automation, but introduces credentials, repository discovery, write permissions, and a larger failure surface before the base template has been used in production.

Approach B is selected because it closes the present safety gaps while keeping policy distribution automation out of the first hardening release.

## 4. Bootstrap behavior

`scripts/initialize-project.ps1` will keep the existing replacement behavior but add a pre-write gate.

Before changing any file, it must verify:

1. The command is running inside a Git repository.
2. The current branch is named, is not detached, and is not `DefaultBranch`.
3. The working tree and index are clean.
4. No merge, rebase, cherry-pick, or revert is in progress.
5. The selected primary remote has fetch and push URLs.
6. Every normalized remote URL matches `github.com/<RepositoryFullName>`.
7. Required template files exist.
8. The policy version is non-empty and matches the central policy file.

The existing `-Force` dirty-tree bypass will be removed. The script will support PowerShell `-WhatIf` through `SupportsShouldProcess`, print the resolved project values and target files before writing, and call `ShouldProcess` before the first mutation.

If any gate fails, the script must stop without changing files. Repository URLs must be normalized without printing credentials, queries, or fragments.

## 5. Policy integrity checks

The PowerShell and Bash checkers will share the same invariants:

- Required policy, guide, prompt, script, workflow, Claude, and template files exist.
- Forbidden tracked local or override files are absent.
- `.claude/settings.json` is valid JSON and `autoMemoryEnabled` is exactly `false`.
- `CLAUDE.md` imports `@AGENTS.md`.
- `POLICY_VERSION` is non-empty and matches `docs/AI_DEVELOPMENT_POLICY.md`.
- Initialized repositories contain no unresolved placeholders in `AGENTS.md`, `docs/PROJECT_GUIDE.md`, or `README.md`.
- Initialized `AGENTS.md` contains the same policy version.

Both checkers will accept an explicit template-placeholder option. GitHub Actions will pass that option only when `github.repository` equals `alclssna33/ai-project-template`; downstream repositories must pass without it.

## 6. Line endings and CI

A root `.gitattributes` will enforce:

```gitattributes
*.sh  text eol=lf
*.ps1 text eol=crlf
*.md  text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.json text eol=lf
```

GitHub Actions will contain separate Ubuntu and Windows jobs so each native checker runs on every pull request and push to `main`. Job names will remain stable because they become required-check identifiers after the workflow has succeeded on `main`.

The workflow will retain `contents: read` and will not receive write permissions.

## 7. GitHub administration sequence

Repository settings are an administrative change and are not hidden inside the file PR.

Before or during the Draft PR:

- Set `is_template=true`.
- Keep squash merge enabled.
- Disable merge commits and rebase merges.
- Enable automatic head-branch deletion.

After the v1.1 PR is merged and both new workflow jobs succeed on `main`:

- Create an active branch ruleset targeting `refs/heads/main`.
- Require changes through pull requests.
- Require conversation resolution.
- Block branch deletion.
- Block non-fast-forward updates.
- Require the two stable policy-check job names.
- Configure no routine bypass actor.

The ruleset must not be created with required checks before GitHub has observed successful runs for those check names.

## 8. Validation

The implementation is accepted only if all of the following pass:

- PowerShell parser validation for both `.ps1` scripts.
- Bash syntax validation against the committed `.sh` content.
- Template-mode PowerShell and Bash policy checks.
- A clean disposable clone can run bootstrap and then pass normal policy checks.
- Bootstrap rejects execution on the default branch.
- Bootstrap rejects a dirty tree.
- Bootstrap rejects a mismatched repository identity.
- `-WhatIf` leaves the disposable clone clean.
- No unresolved target placeholders remain after successful bootstrap.
- `git diff --check` passes and the complete PR diff contains only planned files.
- Both GitHub Actions jobs pass on the PR.

## 9. Rollback

- File changes are reverted through a new PR; history is not rewritten.
- Merge-method and template settings can be restored through repository settings.
- If the ruleset blocks legitimate maintenance, disable its enforcement temporarily only with explicit user approval, document the reason, and correct the rule through the repository's administrative audit trail.
- Downstream repositories created before v1.1 remain independent and are not changed automatically.

## 10. Completion criteria

Version 1.1 is complete when the file PR is reviewed and squash-merged, the new workflow succeeds on `main`, the final ruleset is active, and a generated disposable project passes bootstrap and policy validation from the merged template.
