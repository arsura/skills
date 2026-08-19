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
