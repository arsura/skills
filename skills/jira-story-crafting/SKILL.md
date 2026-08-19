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

1. **Collect input**: requirement, Jira issue key (e.g. `PROJ-123`), optional context. Ask only for what is missing.
2. **Fetch latest Jira state** when an issue key exists — before drafting and again immediately before publish (see [Read before write](#read-before-write)).
3. **Draft** WHO / WHAT / WHY and Acceptance Criteria from the **live Jira description + user request**, not stale chat history. Note gaps as **Open Questions** while drafting AC.
4. **Validate WHY** (see [WHY validation](#why-validation)).
5. **Show draft + Open Questions** in chat unless the user asked to skip review or publish directly.
6. **Publish to Jira** via Atlassian MCP once approved.

## WHO / WHAT / WHY

| Field | Rule |
|-------|------|
| **WHO** | The user or role who benefits. One short phrase or sentence. |
| **WHAT** | The capability or change. Concrete and testable. No implementation detail unless the user required it. |
| **WHY** | Business or user outcome. Must **not** restate WHAT. See [WHY validation](#why-validation). |

**Layout:** labels bold, content plain. **One paragraph** with soft line breaks between rows (Shift+Enter / ADF `hardBreak`), not separate paragraphs.

**Chat:** `**WHO:**` / `**WHAT:**` / `**WHY:**` on separate lines.

**Jira:** ADF only (`contentFormat: "adf"`). One `paragraph` node; bold labels via `strong`; rows separated by `hardBreak`. Never use `<br>`.

## WHY validation

Before finalizing, WHY must pass all three:

1. **Not a WHAT paraphrase** — if swapping WHAT and WHY still reads fine, rewrite WHY.
2. **Answers "so what?"** — pain, risk, cost, or value.
3. **Outcome, not mechanism** — benefit, not the feature itself.

If WHY fails, rewrite silently. Do not publish a bad WHY. More examples: [examples.md](examples.md)

## Acceptance Criteria

Write in **English**. Keep each scenario short. No numbered AC items. **Never use em dash** (`—` or `–`).

- Heading: `## Acceptance Criteria` (H2). Scenario title: `### [title]` (H3).
- **GIVEN**, **WHEN**, **THEN**, **AND** are always bold. Use bullets; indent **AND** under GIVEN or THEN.
- One scenario = one behavior. Cover happy path and edge cases the user mentioned. Do not invent scope.
- **Code-like tokens** (field names, types, enums, URL schemes): backticks in chat, ADF `code` mark in Jira. See [Full description template](#full-description-template).

## Dividers

Use `------` in chat and ADF `{ "type": "rule" }` in Jira:

- after WHO / WHAT / WHY, before Acceptance Criteria
- between each AC scenario
- after the final AC scenario, before any appendix the user requested
- never after the last section in the description

## Read before write

When an issue key exists, call `getJiraIssue` with `fields: ["summary", "description"]` before drafting and again immediately before `editJiraIssue`.

- Treat the latest fetch as source of truth. Do not rebuild from an earlier chat draft.
- Respect manual edits: start from the latest Jira content and apply only the user's new request.
- **Partial update** (default): change only what was asked; keep everything else.
- **Full rewrite**: only when the user explicitly asks.
- If Jira differs from what you assumed, mention the diff briefly before publishing.

Typical failure: AI wrote v1 → human fixed v2 → AI publishes v1 again.

## Open Questions

Capture unclear or undecided scope while drafting AC. Do not guess.

- Add to every chat draft (English, bullets, no numbers). Prefer 1–5 focused questions.
- Do not repeat questions the user already answered.
- **Chat only** unless the user asks to put them in Jira.
- If a question blocks AC, ask and wait. If AC can proceed with a reasonable assumption, draft anyway and list the assumption under Open Questions.

## Full description template

**Chat preview:**

```markdown
**WHO:** ...
**WHAT:** ...
**WHY:** ...

------

## Acceptance Criteria

### [Scenario title]
- **GIVEN:**
  - [precondition]
- **WHEN:** [action]
- **THEN:**
  - [outcome]
  - **AND:** [additional outcome]

------

### [Next scenario]
...

------

### [Appendix, if user requested]
...
```

**Jira ADF mapping:**

- WHO / WHAT / WHY → one `paragraph` with `hardBreak` between rows; labels use `strong`
- dividers → `{ "type": "rule" }` per [Dividers](#dividers)
- Acceptance Criteria → `heading` level 2; each scenario → `heading` level 3
- GIVEN / WHEN / THEN → `bulletList` / nested `listItem`; labels use `strong`
- code-like tokens → `code` mark on `text` nodes

Minimal ADF for WHO / WHAT / WHY:

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

Set `summary` from WHAT (short, imperative, no period) unless the user specified a title or the latest Jira summary should stay.

## Publish to Jira (Atlassian MCP)

Server: `user-atlassian-mcp-official`.

1. **cloudId** — Jira URL hostname first; otherwise `getAccessibleAtlassianResources`.
2. **Existing issue** — fetch twice (see [Read before write](#read-before-write)); merge into latest description; `editJiraIssue` with `contentFormat: "adf"`, full ADF `description`, and `summary` only if it should change.
3. **New issue** — `createJiraIssue` with `issueTypeName: "Story"` (or user-named type), `projectKey`, `summary`, `description`, `contentFormat: "adf"`.
4. **Confirm** — return issue key and link. If MCP auth fails, ask the user to authenticate and retry. Never pretend the issue was updated.

## Style

- Short, scannable sentences. English only in the story and AC.
- Default sections: WHO / WHAT / WHY, Acceptance Criteria, plus appendix only when the user asks (e.g. CSV field spec).
- Do not add other sections (Out of scope, Technical notes, Import policy, etc.) unless requested.
- Infer reasonable WHO/WHAT/WHY from minimal input; use Open Questions when AC scope is unclear.

## Checklist before publish

- [ ] Latest Jira description fetched (twice if editing)
- [ ] Draft merged from live Jira + user request, not stale chat
- [ ] WHY passes validation; WHO/WHAT/WHY in one ADF paragraph with `hardBreak`
- [ ] AC uses H2/H3, GWT structure, dividers, and code marks where needed
- [ ] No numbered AC, em dash, or `<br>`
- [ ] Open Questions in chat when ambiguities remain
