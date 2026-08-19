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
6. lifecycle callees     (resetDatabase, applyMigrations, …) — directly below hooks
7. tests + callees       (interleaved — see below)
```

## Core pattern: test → callees → next test

After each `Test*`, append **every function it calls**, in **the order they appear in the test body**, before the next test.

```go
func (s *Suite) TestCreateInvoice() {
    s.seedCustomer(...)
    actual := s.createInvoice(...)
    s.assertInvoice(expected, actual)
}

func (s *Suite) seedCustomer(...) { ... }        // ← right below test

func (s *Suite) createInvoice(...) { ... }       // ← next callee

func (s *Suite) assertInvoice(...) {              // ← next callee
    s.assertLineItemsEqual(...)
}

func (s *Suite) assertLineItemsEqual(...) { ... } // ← deepest, still below assertInvoice

func (s *Suite) TestCreateInvoiceWithTax() { ... } // ← next test after helper chain
```

## Shared helpers across tests

- Define a helper **once**, on **first use** — directly under that test's position in the chain.
- Later tests that **reuse** the same helpers come **after the whole helper block** — reader already saw them above.
- If a later test calls a **new** helper, put that helper **directly under that test**, before any following tests.

```go
func (s *Suite) TestPrimaryFlow() {
    user := makeUser()              // 1st use of makeUser
    s.register(user)
    s.assertProfile(s.fetchProfile(...))
}

func makeUser() { ... }             // immediately below TestPrimaryFlow
func (s *Suite) register(...) { ... }
func (s *Suite) fetchProfile(...) { ... }
func (s *Suite) assertProfile(...) { ... }

func (s *Suite) TestWithOrganization() {
    user := makeUser()              // reuses makeUser — already defined above
    s.createOrganization(user)
    s.register(user)
    ...
}

func (s *Suite) createOrganization(...) { ... } // NEW — directly below TestWithOrganization

func (s *Suite) TestAnotherReuse() { ... }      // only reuses existing helpers
```

## Lifecycle hooks

Same immediate-callee rule:

```go
func (s *Suite) SetupSuite() {
    s.resetDatabase()
    s.applyMigrations(...)
}

func (s *Suite) resetDatabase() { ... }    // directly below SetupSuite block
func (s *Suite) applyMigrations(...) { ... }
```

## Migrations / services

```go
func registerCreatePostsTable() { ... }

func upCreatePostsTable(ctx, conn) error {
    count, err := countRows(conn, "posts")
    return conn.Exec(ctx, query)
}

func countRows(...) { ... }   // directly below upCreatePostsTable
```

## Anti-patterns

```go
// BAD — all tests first, helpers at bottom (reader must scroll far)
func TestA() { makeUser(); register() }
func TestB() { makeUser() }
func makeUser() { ... }   // ← too far from TestA
func register() { ... }

// BAD — helpers before tests
func register() { ... }
func TestA() { register() }

// BAD — alphabetical among helpers
func assertProfile() { ... }
func fetchProfile() { ... }
func register() { ... }
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
