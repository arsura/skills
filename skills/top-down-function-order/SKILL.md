---
name: top-down-function-order
description: >-
  Orders functions for top-down reading: each caller is immediately followed by
  its callees in call order (newspaper style). Use when writing or reorganizing
  Go code, tests, migrations, or when the user asks for readable function order,
  top-down layout, or caller-above-callee structure.
---

# Top-Down Function Order

Order functions so a reader **scrolls down and meets each callee immediately** — never hunt helpers at the bottom of the file.

**Rule:** If `A` calls `B`, put `B` **on the very next function(s)** below `A` (same call order). Do not batch all helpers at the end.

This is **not** alphabetical, **not** helpers-first, and **not** "all tests then all helpers".

## File skeleton

```
1. package + imports
2. constants / vars
3. types
4. Test runner / entry points
5. lifecycle hooks (SetupSuite, SetupTest, TearDown*)
6. lifecycle callees     (resetSchema, runMigrateUpTo, …) — directly below hooks
7. tests + callees       (interleaved — see below)
```

## Core pattern: test → callees → next test

After each `Test*`, append **every function it calls**, in **the order they appear in the test body**, before the next test.

```go
func (s *Suite) TestAdEvents() {
    s.insertAdEvents(...)
    actual := s.queryAdEvents(...)
    s.assertAdEvents(expected, actual)
}

func (s *Suite) insertAdEvents(...) { ... }      // ← right below test

func (s *Suite) queryAdEvents(...) { ... }       // ← next callee

func (s *Suite) assertAdEvents(...) {           // ← next callee
    s.assertAdEventEqual(...)
}

func (s *Suite) assertAdEventEqual(...) { ... }   // ← deepest, still below assertAdEvents

func (s *Suite) TestAdEventsDistributed() { ... }  // ← next test after helper chain
```

## Shared helpers across tests

- Define a helper **once**, on **first use** — directly under that test's position in the chain.
- Later tests that **reuse** the same helpers come **after the whole helper block** — reader already saw them above.
- If a later test calls a **new** helper, put that helper **directly under that test**, before any following tests.

```go
func (s *Suite) TestPrimaryFlow() {
    row := makeRow()              // 1st use of makeRow
    s.insert(row)
    s.assert(s.query(...))
}

func makeRow() { ... }            // immediately below TestPrimaryFlow
func (s *Suite) insert(...) { ... }
func (s *Suite) query(...) { ... }
func (s *Suite) assert(...) { ... }

func (s *Suite) TestWithExtraSetup() {
    row := makeRow()              // reuses makeRow — already defined above
    s.insertRegion(row)
    s.insert(row)
    ...
}

func (s *Suite) insertRegion(...) { ... }  // NEW — directly below TestWithExtraSetup

func (s *Suite) TestAnotherReuse() { ... } // only reuses existing helpers
```

## Lifecycle hooks

Same immediate-callee rule:

```go
func (s *Suite) SetupSuite() {
    s.resetSchema()
    s.runMigrateUpTo(...)
}

func (s *Suite) resetSchema() { ... }       // directly below SetupSuite block
func (s *Suite) runMigrateUpTo(...) { ... }
```

## Migrations / services

```go
func registerUpWarmup() { ... }

func upWarmup(ctx, conn) error {
    count, err := countTableRows(...)
    return conn.Exec(ctx, query)
}

func countTableRows(...) { ... }   // directly below upWarmup
```

## Anti-patterns

```go
// BAD — all tests first, helpers at bottom (reader must scroll far)
func TestA() { makeRow(); insert() }
func TestB() { makeRow() }
func makeRow() { ... }   // ← too far from TestA
func insert() { ... }

// BAD — helpers before tests
func insert() { ... }
func TestA() { insert() }

// BAD — alphabetical among helpers
func assert(...) { ... }
func insert(...) { ... }
func query(...) { ... }
```

## When editing

1. Make the logic change.
2. Reorder so every callee sits **directly under its caller** — no behavior change.

## Checklist

- [ ] Reading a test, the next functions down are exactly what it calls, in order
- [ ] No helper block dumped at file bottom
- [ ] Deepest callee is last in its local chain
- [ ] Reused helpers appear before later tests that call them
- [ ] New helpers for a later test sit directly under that test
