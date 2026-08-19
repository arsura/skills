---
paths:
  - "**/*.go"
---

# Top-Down Function Order

If `A` calls `B`, put `B` **on the very next function(s)** below `A` (same call order).

**Not** alphabetical, **not** helpers-first, **not** "all tests then all helpers".

## File skeleton

```
package + imports → constants/vars → types → entry points
→ lifecycle hooks → lifecycle callees (directly below)
→ tests + callees (interleaved)
```

## Core pattern

After each `Test*`, append every function it calls, **in call order**, before the next test:

```go
func (s *Suite) TestCreateInvoice() {
    s.seedCustomer(...)
    actual := s.createInvoice(...)
    s.assertInvoice(expected, actual)
}

func (s *Suite) seedCustomer(...) { ... }
func (s *Suite) createInvoice(...) { ... }
func (s *Suite) assertInvoice(...) {
    s.assertLineItemsEqual(...)
}
func (s *Suite) assertLineItemsEqual(...) { ... }

func (s *Suite) TestCreateInvoiceWithTax() { ... }
```

## Shared helpers

- Define on **first use**, directly under that test's chain.
- Reused helpers: later tests come **after** the helper block.
- **New** helper for a later test: put it directly under that test.

## Anti-patterns

```go
// BAD — helpers at bottom, far from callers
func TestA() { makeUser(); register() }
func TestB() { makeUser() }
func makeUser() { ... }
func register() { ... }

// BAD — helpers before tests
func register() { ... }
func TestA() { register() }
```

## When editing

1. Make the logic change.
2. Reorder so every callee sits directly under its caller — no behavior change.
