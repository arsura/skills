---
name: jira-story-crafting
description: >-
  Drafts Jira user stories in WHO/WHAT/WHY plus GIVEN/WHEN/THEN acceptance
  criteria, validates WHY, and updates Jira via Atlassian MCP. Use when writing
  or refining a user story, acceptance criteria, Jira ticket description, or
  when the user mentions WHO WHAT WHY, GIVEN WHEN THEN, open questions, or wants a
  story pushed to Jira.
---

# Jira Story Crafting

Turn rough requirements into a concise English user story and push it to Jira.

## Workflow

1. **Collect input** from the user: requirement, Jira issue key (e.g. `PROJ-123`), optional context (persona, constraints, edge cases). Ask only for what is missing.
2. **Draft** WHO / WHAT / WHY and Acceptance Criteria (see formats below). While drafting AC, note gaps and ambiguities as **Open Questions** (see [Open Questions](#open-questions)).
3. **Validate WHY** before showing or publishing (see [WHY validation](#why-validation)).
4. **Show draft + Open Questions** in chat for review when the user did not ask to skip review. If Open Questions would materially change AC, ask them before publishing to Jira.
5. **Publish to Jira** via Atlassian MCP once the draft is approved or the user asked to update Jira directly.

## WHO / WHAT / WHY

| Field | Rule |
|-------|------|
| **WHO** | The user or role who benefits. One short phrase or sentence. |
| **WHAT** | The capability or change. Concrete and testable. No implementation detail unless the user required it. |
| **WHY** | Business or user outcome. Must **not** restate WHAT. See validation below. |

Use this exact layout (labels bold, content plain):

```markdown
**WHO:** [role or persona]
**WHAT:** [capability or change]
**WHY:** [reason this matters]
```

## WHY validation

Before finalizing, check WHY passes all of these:

1. **Not a WHAT paraphrase** — if you swap WHAT and WHY and they still make sense, rewrite WHY.
2. **Answers "so what?"** — states pain, risk, cost, or value (time saved, errors reduced, revenue, compliance, etc.).
3. **Outcome, not mechanism** — describes the benefit, not the feature itself.

If WHY fails, rewrite silently and use the fixed version in the output. Do not publish a bad WHY.

More examples: [examples.md](examples.md)

## Acceptance Criteria

Write in **English**. Keep each scenario short. No numbered AC items (so they can be reordered). **Never use em dash** (`—` or `–`); use a comma, period, or rephrase instead.

Section heading: **Acceptance Criteria** (bold).

Each scenario starts with a one-line title (plain text, no number). Structure:

```markdown
**Acceptance Criteria**

[Short scenario title]
- **GIVEN:**
  - [precondition]
  - **AND:** [additional precondition]
- **WHEN:** [action or trigger]
- **THEN:**
  - [expected outcome]
  - **AND:** [additional outcome]
```

Rules:

- **GIVEN**, **WHEN**, **THEN**, **AND** are always bold.
- Use bullets; indent **AND** under its parent (GIVEN or THEN).
- One scenario = one behavior. Split unrelated behaviors into separate scenarios.
- Cover happy path and important edge cases the user mentioned. Do not invent scope.

## Open Questions

While writing AC, capture anything unclear, undecided, or missing from the input. Do not guess; surface it for the user.

Add **Open Questions** to every chat draft (English, bullet list, no numbers). Ask only questions that matter for scope or AC. Keep each question short and specific.

```markdown
**Open Questions**

- Should paused orders auto-resume after a fixed duration or only manual resume?
- Does the owner get notified when pause expires?
```

Rules:

- Raise questions you hit **while** drafting AC (edge cases, error handling, permissions, limits, UX choices).
- Prefer 1–5 focused questions over a long laundry list.
- If the user already answered something, do not repeat it.
- **Do not** include Open Questions in the Jira description unless the user asks to.
- If a question blocks AC, ask it and wait. If AC can proceed with a reasonable assumption, draft AC anyway, list the assumption under Open Questions, and let the user confirm.

## Full description template

Combine story and AC for Jira `description`:

```markdown
**WHO:** ...
**WHAT:** ...
**WHY:** ...

**Acceptance Criteria**

...
```

Set `summary` from WHAT (short, imperative, no period) unless the user specified a title.

## Publish to Jira (Atlassian MCP)

Use server `user-atlassian-mcp-official`.

1. **Resolve cloudId**
   - User gave a Jira URL → pass the site hostname as `cloudId` first.
   - Otherwise call `getAccessibleAtlassianResources` and pick the matching site.

2. **Existing issue** (user gave a key like `PROJ-123`)
   - `getJiraIssue` with `issueIdOrKey` to read current summary/description.
   - Merge carefully: replace description with the new draft unless the user asked to append or preserve parts.
   - `editJiraIssue` with `contentFormat: "markdown"` and `fields`:
     - `description`: full template above
     - `summary`: only if it should change

3. **New issue** (user gave project + type, no key)
   - `createJiraIssue` with `issueTypeName: "Story"` (or the type the user named), `projectKey`, `summary`, `description`, `contentFormat: "markdown"`.

4. **Confirm** — return the issue key and link after a successful create or edit.

If MCP auth fails, tell the user to authenticate the Atlassian MCP server and retry. Do not pretend the issue was updated.

## Style

- Short, scannable sentences. Prefer plain words over jargon.
- Write only in English in the story and AC.
- Do not add extra Jira sections (no "Out of scope", "Technical notes", etc.) unless requested. Open Questions are for chat only by default.
- Infer reasonable WHO/WHAT/WHY from minimal input; use Open Questions instead of silent guessing when AC would change.

## Checklist before publish

- [ ] WHO / WHAT / WHY present; labels bold
- [ ] WHY is outcome/value, not a WHAT repeat
- [ ] AC uses GIVEN / WHEN / THEN / AND with correct bullets and indent
- [ ] No numbered AC items; no em dash
- [ ] All text in English
- [ ] Open Questions listed in chat when ambiguities exist
- [ ] Jira issue key or create params confirmed
