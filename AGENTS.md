# Agent Operating Rules

## Required Workflow
For every coding task:
1. Work in an isolated worktree under `/home/kevbot/agent-worktrees/<RepoName>/<task-slug>`.
2. Use a branch named `agent/<task-slug>`.
3. Never work directly on `main` or the default branch.
4. Inspect relevant files before editing.
5. Prefer the smallest safe change.
6. Run available repo-local validation.
7. Commit changes.
8. Push the branch.
9. Open a pull request against the default branch.
10. Report PR URL, files changed, validation performed, and risks.

## Approval Gates
The agent may create branches, commits, pushes, and pull requests during assigned repo tasks.

The agent may NOT do any of the following unless Kevin gives a separate explicit approval message naming the action and target PR or workflow:
- merge a PR
- delete a remote branch
- delete a local worktree
- run a release/build/deploy workflow
- deploy
- submit to TestFlight or any app store
- modify signing/certificate/provisioning/secrets

Valid approval examples:
- "Merge PR #261 and delete the branch."
- "Run the iOS build workflow for PR #261."
- "Close PR #260 and delete the branch."

Invalid approvals:
- "looks good"
- "worked"
- "continue"
- "nice"
- "ship it" unless it names the exact PR/action

## Hard Limits
Do not touch certificate repositories.
Do not change signing, certificate, provisioning, Fastlane match storage, secrets, tokens, or environment files unless explicitly instructed.
Do not make destructive data changes unless explicitly instructed.
Do not merge or deploy without explicit approval.

## Pull Request Expectations
Every PR should include:
- Summary
- Files changed
- Validation performed
- Known risks
- Manual test notes when full validation is not possible locally

## Repo Notes
PizzaChickenPop is a Swift/SpriteKit iOS app that uses `project.yml`, XcodeGen, Fastlane, and Fastlane Match. Its generated Xcode project may be absent until `xcodegen generate` is run on a suitable host.

When available on a suitable macOS/Xcode host, prefer repo-local validation such as:
- `xcodegen generate`
- `xcodebuild build -scheme PizzaChicken`

Do not run Fastlane Match, TestFlight deployment, release workflows, signing setup, or certificate operations without explicit approval.
