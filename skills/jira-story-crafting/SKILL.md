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

1. **Collect input** from the user: requirement, Jira issue key (e.g. `PROJ-123`), optional context. Ask only for what is missing.
2. **Fetch latest Jira state first** when an issue key exists — before drafting and again immediately before publish (see [Read before write](#read-before-write)).
3. **Draft** WHO / WHAT / WHY and Acceptance Criteria from the **live Jira description + user request**, not stale chat history. While drafting AC, note gaps as **Open Questions**.
4. **Validate WHY** before showing or publishing (see [WHY validation](#why-validation)).
5. **Show draft + Open Questions** in chat for review when the user did not ask to skip review.
6. **Publish to Jira** via Atlassian MCP once approved or the user asked to update Jira directly.

## WHO / WHAT / WHY

| Field | Rule |
|-------|------|
| **WHO** | The user or role who benefits. One short phrase or sentence. |
| **WHAT** | The capability or change. Concrete and testable. No implementation detail unless the user required it. |
| **WHY** | Business or user outcome. Must **not** restate WHAT. See validation below. |

Use this layout (labels bold, content plain). **One paragraph, soft line breaks** between rows (Shift+Enter in Jira), not separate paragraphs.

**Chat preview** (readable):

```markdown
**WHO:** [role or persona]
**WHAT:** [capability or change]
**WHY:** [reason this matters]
```

**Jira publish** — use ADF (`contentFormat: "adf"`), not markdown. Put WHO / WHAT / WHY in **one** `paragraph` node; separate rows with `hardBreak`. **Never use `<br>`** — Jira markdown renders it as literal text.

```json
{
  "type": "paragraph",
  "content": [
    { "type": "text", "text": "WHO: ", "marks": [{ "type": "strong" }] },
    { "type": "text", "text": "Ops" },
    { "type": "hardBreak" },
    { "type": "text", "text": "WHAT: ", "marks": [{ "type": "strong" }] },
    { "type": "text", "text": "Import records via CSV upload" },
    { "type": "hardBreak" },
    { "type": "text", "text": "WHY: ", "marks": [{ "type": "strong" }] },
    { "type": "text", "text": "Merchants miss accurate recommendations without up-to-date config" }
  ]
}
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

Section heading: `## Acceptance Criteria` (H2).

Each scenario title: `### [Short scenario title]` (H3). Put a **divider between scenarios**, not before the first or after the last. Structure:

```markdown
## Acceptance Criteria

### [Short scenario title]
- **GIVEN:**
  - [precondition]
  - **AND:** [additional precondition]
- **WHEN:** [action or trigger]
- **THEN:**
  - [expected outcome]
  - **AND:** [additional outcome]

------

### [Next scenario title]
- **GIVEN:**
  ...
```

Rules:

- **GIVEN**, **WHEN**, **THEN**, **AND** are always bold.
- Use bullets; indent **AND** under its parent (GIVEN or THEN).
- One scenario = one behavior. Split unrelated behaviors into separate scenarios.
- Separate each AC scenario with `------` (chat) or ADF `rule` node (Jira). No divider after the final scenario.
- Cover happy path and important edge cases the user mentioned. Do not invent scope.

## Read before write

When an issue key exists, **always** call `getJiraIssue` with `fields: ["summary", "description"]` (or `["*all"]` if needed):

1. **Before drafting** — treat the returned description as the current source of truth.
2. **Immediately before `editJiraIssue`** — fetch again so human or prior AI edits during the session are not lost.

Merge rules:

- **Do not** rebuild from an earlier chat draft if Jira has newer content.
- **Do not** ignore manual edits. If a human changed WHO / WHAT / WHY / AC, start from their version and apply only the user's new request.
- **Partial update** (default): change only what the user asked for; keep everything else from the latest fetch.
- **Full rewrite**: only when the user explicitly asks to rewrite the whole story.
- If latest Jira content differs from what you assumed, mention the diff briefly before publishing.

Typical failure to avoid: AI wrote v1 → human fixed v2 → AI publishes v1 again. Always publish from v2 + new changes.

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

**Chat preview:**

```markdown
**WHO:** ...
**WHAT:** ...
**WHY:** ...

## Acceptance Criteria

### ...
------

### ...
```

**Jira `description` field** — ADF document (`contentFormat: "adf"`):

- WHO / WHAT / WHY: one `paragraph` with `hardBreak` between rows (see above)
- `## Acceptance Criteria` → `heading` level 2
- each scenario title → `heading` level 3
- GIVEN / WHEN / THEN → `bulletList` / `listItem` / nested lists; bold labels via `strong` mark
- between scenarios → `{ "type": "rule" }` (horizontal divider); omit after the last scenario

Set `summary` from WHAT (short, imperative, no period) unless the user specified a title or the latest Jira summary should stay.

## Publish to Jira (Atlassian MCP)

Use server `user-atlassian-mcp-official`.

1. **Resolve cloudId**
   - User gave a Jira URL → pass the site hostname as `cloudId` first.
   - Otherwise call `getAccessibleAtlassianResources` and pick the matching site.

2. **Existing issue** (user gave a key like `PROJ-123`)
   - `getJiraIssue` — **required**, twice: before draft and before edit (see [Read before write](#read-before-write)).
   - Merge the draft into the **latest** description; do not overwrite human edits unless asked.
   - `editJiraIssue` with `contentFormat: "adf"` and `fields`:
     - `description`: full ADF document
     - `summary`: only if it should change

3. **New issue** (user gave project + type, no key)
   - `createJiraIssue` with `issueTypeName: "Story"` (or the type the user named), `projectKey`, `summary`, `description`, `contentFormat: "adf"`.

4. **Confirm** — return the issue key and link after a successful create or edit.

If MCP auth fails, tell the user to authenticate the Atlassian MCP server and retry. Do not pretend the issue was updated.

## Style

- Short, scannable sentences. Prefer plain words over jargon.
- Write only in English in the story and AC.
- Do not add extra Jira sections (no "Out of scope", "Technical notes", etc.) unless requested. Open Questions are for chat only by default.
- Infer reasonable WHO/WHAT/WHY from minimal input; use Open Questions instead of silent guessing when AC would change.

## Checklist before publish

- [ ] `getJiraIssue` fetched latest description (twice if editing existing issue)
- [ ] Draft built from live Jira content + user request, not stale chat draft
- [ ] WHO / WHAT / WHY in one ADF paragraph with `hardBreak`; labels bold; no `<br>`
- [ ] WHY is outcome/value, not a WHAT repeat
- [ ] Acceptance Criteria is H2; each scenario title is H3
- [ ] AC uses GIVEN / WHEN / THEN / AND with correct bullets and indent
- [ ] Divider (`------` / ADF `rule`) between AC scenarios, not after the last one
- [ ] No numbered AC items; no em dash
- [ ] All text in English
- [ ] Open Questions listed in chat when ambiguities exist
- [ ] Jira issue key or create params confirmed
