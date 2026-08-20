# skills

Personal agent skills and rules for **Cursor** and **Claude Code**.

**Personal setup, might not work for everyone else** 😅

## Skills

### jira-story-crafting

Draft Jira user stories as **WHO / WHAT / WHY** plus **GIVEN / WHEN / THEN** acceptance criteria, validate WHY, surface **Open Questions** while drafting, and push to Jira via Atlassian MCP.

**Use when:** writing or refining a user story, acceptance criteria, or updating a Jira ticket description.

**Install skill:**

```bash
npx skills add arsura/skills --skill jira-story-crafting -g -a cursor -a claude-code
```

---

### top-down-function-order

Order Go functions **top-down (newspaper style)** — each caller immediately followed by its callees in call order. Never dump helpers at the bottom of the file.

**Use when:** writing or reorganizing Go code, tests, migrations, or when you want readable function order.

**Install skill:**

```bash
npx skills add arsura/skills --skill top-down-function-order -g -a cursor -a claude-code
```

**Install rule:**

```bash
git clone git@github.com:arsura/skills.git /tmp/skills && /tmp/skills/scripts/install-rules.sh --global
```

---

### explicit-expects

Write Go tests whose `want` is **hand-written literals compared in full with one assert** — no `Contains`, no count-only DB asserts, no production constants/enums inside the expectation. Covers unit tests, IT/HTTP JSON responses, validation errors, mappers, and DB state.

**Use when:** writing or reviewing unit tests, IT tests, table-driven tests, validation/error tests, or when you want explicit hardcoded expectations.

**Install skill:**

```bash
npx skills add arsura/skills --skill explicit-expects -g -a cursor -a claude-code
```

---

## Install

**Skills:**

```bash
npx skills add arsura/skills -g -a cursor -a claude-code
```

**Rules:**

```bash
git clone git@github.com:arsura/skills.git /tmp/skills && /tmp/skills/scripts/install-rules.sh --global
```

**Everything (copy-paste):**

```bash
npx skills add arsura/skills -g -a cursor -a claude-code
git clone git@github.com:arsura/skills.git /tmp/skills && /tmp/skills/scripts/install-rules.sh --global
```

---
