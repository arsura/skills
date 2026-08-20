---
name: explicit-expects
description: >-
  Writes Go tests whose expected value is a hand-written literal compared in
  full with one assert — no Contains, no length/count-only asserts, no
  production functions, constants or enums inside the expectation. Use when
  writing or reviewing unit tests, IT/HTTP tests, table-driven tests,
  validation or mapper tests, or when the user asks for explicit, hardcoded,
  or full-value test expectations.
---

# Explicit Expects

A test is a **specification written by hand**. The expected value must be readable as "this is the correct output", by a reviewer who never opens the production file.

Two questions decide every assertion:

1. **Where did `want` come from?** → From your head and the spec. Never from production code.
2. **How much of `got` did you check?** → All of it. Once.

## The four laws

### 1. Never call production code to build `want`

If the expectation is computed by the code under test — a helper, a constant, an enum, a mapper, a formatter — the test passes when production is wrong. It stays green through the exact bug it exists to catch (a *tautological test*, "The Liar").

```go
// BAD — production decides what "correct" is
assert.Equal(t, FieldKeyEmail.String(), errs[0].Field)
assert.Equal(t, ErrRequired, errs[0].Reason)
assert.Equal(t, buildOrderID(cart), got.ID)
want := cart.ToOrder()               // comparing production to itself

// GOOD — the test decides
want := []FieldError{{Field: "email", Reason: "required"}}
assert.Equal(t, want, form.Validate())
```

Rule of thumb: **if you cannot write the expected output without running the code, you do not yet have a spec.** Go find the spec first.

### 2. Hardcode every value — types may be shared, values never

You need the production *type* to compare structs; you never need its *values*.

```go
// BAD — enum/constant re-derives the expectation
want := Order{Status: StatusActive, Currency: DefaultCurrency, Tier: TierGold}

// GOOD — literals; Go converts untyped constants to the defined type
want := Order{Status: "ACTIVE", Currency: "THB", Tier: 2} // Tier 2 = gold
```

This is deliberate friction. Renaming `StatusActive` must not silently change the contract; changing its *value* from `"ACTIVE"` to `"active"` is a wire-format change and **must** fail a test.

For a JSON contract, skip the model entirely and compare the JSON string (law 3) — no type, no enum, nothing to re-derive.

### 3. Expect the whole return value, in one assert

Build `want`, call the function once, compare once.

```go
got, err := cart.ToOrder()
require.NoError(t, err)
assert.Equal(t, want, got)
```

Banned as the *primary* check: `Contains`, `Len` + one field, `NotEmpty`, `ElementsMatch` on a projection, `CountDocuments`, "spot-check three fields". Each of them passes while the other fields are garbage, and a wall of them is *Assertion Roulette* — a failure line that does not tell you what broke.

- Deterministic order → expect the **full ordered slice**. If production's order is accidental, fix production and pin the order here.
- Returns `nil` → expect `nil`, not `[]T{}`. They are different values to a caller.
- `assert.Equal(t, want, got)` — want first, so the diff reads the right way round. With go-cmp: `cmp.Diff(want, got)` printed as `(-want +got)`.

### 4. The expectation lives in the test body

No shared `expectedUser()` builder, no `validationTableValues(err)` unwrapper, no fixture file holding the answer. A reader must see input and expected output side by side (*Mystery Guest* / *Obscure Test*).

Tests are **DAMP, not DRY**: duplicated literals across cases are the point — each case is independently readable, and one case changing does not drag the others with it. Share *setup* (a DB handle, a server), never *expectations*.

```go
// BAD — the answer is somewhere else, and it asserts a projection
assert.Equal(t, [][]any{{3, "website", "must start with https://", ""}}, validationTableValues(t, err))
```

## Table-driven template

```go
tests := []struct {
    name string
    form SignupForm
    want []FieldError
}{
    {
        name: "valid form has no errors",
        form: SignupForm{Email: "ada@example.com", Password: "hunter2", Age: 30},
        want: nil,
    },
    {
        name: "missing required fields",
        form: SignupForm{},
        want: []FieldError{
            {Field: "email", Reason: "required"},
            {Field: "password", Reason: "required"},
            {Field: "age", Reason: "required"},
        },
    },
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        assert.Equal(t, tt.want, tt.form.Validate())
    })
}
```

One `want` field, one assert. If a case needs a different assertion shape, it is a different test — not an extra flag in the struct.

## By kind of thing under test

### Validation / error values

```go
// GOOD — full slice, literal strings, one Equal
want := []FieldError{
    {Field: "website", Reason: "must start with https://", Hint: "https://acme.example"},
}
assert.Equal(t, want, profile.Validate())

// BAD — length then one field
errs := profile.Validate()
require.Len(t, errs, 1)
assert.Equal(t, "website", errs[0].Field)
```

Error wrapping a structured type — expect the **whole payload**:

```go
wantErr := ValidationError{
    Message: "validation error",
    Info: map[string]any{
        "type": "table",
        "fields": []ErrorField{
            {Key: "row", Type: "number"},
            {Key: "column", Type: "string"},
            {Key: "reason", Type: "string"},
            {Key: "example", Type: "string"},
        },
        "values": []any{
            []any{3, "email", "required", ""},
        },
    },
}

var got *ValidationError
require.ErrorAs(t, err, &got)
assert.Equal(t, wantErr, ValidationError{Message: got.Message, Info: got.Info})
```

Plain errors: assert the exact message string (`assert.EqualError(t, err, "csv file has no data row")`), not `require.Error` alone — the message is the contract users read.

### HTTP / IT responses

The response body **is** the return value. Status code, then the full JSON string.

```go
// GOOD
require.Equal(t, http.StatusOK, rec.Code)
testutil.EqualByJSON(t.T(), `{"imported":2,"skipped":0,"errors":[]}`, res)

// BAD — three substrings prove nothing about the fourth field
assert.Contains(t, res, `"imported":2`)
assert.Contains(t, res, "ctr_state")
```

Non-deterministic field (`timestamp`, generated id) — delete the **named** field, compare everything else:

```go
wantJSON := `{
    "message": "validation error",
    "info": {
        "type": "table",
        "fields": [
            {"Key": "row", "Type": "number"},
            {"Key": "column", "Type": "string"},
            {"Key": "reason", "Type": "string"},
            {"Key": "example", "Type": "string"}
        ],
        "values": [[2, "email", "required", ""]]
    }
}`

var body map[string]json.RawMessage
require.NoError(t, json.Unmarshal([]byte(res), &body))
delete(body, "timestamp")
gotJSON, err := json.Marshal(body)
require.NoError(t, err)
testutil.EqualByJSON(t.T(), wantJSON, string(gotJSON))
```

Deleting a field you named is narrowing you chose and can see. `Contains` is narrowing you cannot see.

### Database state

Assert **what was stored**, never how many rows exist.

```go
// GOOD — read back, compare full records
want := []OrderRecord{
    {CustomerID: "cust_42", SKU: "MUG-01", Qty: 2},
    {CustomerID: "cust_99", SKU: "PEN-02", Qty: 1},
}
assert.Equal(t, want, listOrderRecords(t, db))

// BAD — count says nothing about content
count, _ := coll.CountDocuments(ctx, bson.M{})
assert.Equal(t, int64(2), count)
```

Project into a comparable struct (or `cmpopts.IgnoreFields`) to drop columns the test does not own — `_id`, `created_at`. The read-back helper may be shared; the `want` may not.

### Mappers / entities

```go
want := Order{
    CustomerID: "cust_42",
    Lines: []LineItem{
        {SKU: "MUG-01", Qty: 2, UnitPriceCents: 990},
    },
    TotalCents: 1980,
}
got, err := cart.ToOrder()
require.NoError(t, err)
assert.Equal(t, want, got)
```

`TotalCents: 1980` is written by hand. The moment you write `2 * 990` you have re-implemented production in the test.

## The only legal narrowings

- `require.NoError` / `require.ErrorAs` as a **guard** before the real comparison.
- Deleting or ignoring **named** non-deterministic fields. Better: inject a fixed clock / id generator and expect the real value.
- Unordered results, only when production genuinely cannot guarantee order — and say so in a comment.
- Golden files for payloads too large to read (hundreds of lines). Regenerating one is a code review of the diff, never a blind `-update`.

Everything else — "it's just a smoke test", "the other fields are obvious", "the struct is big" — is not on this list.

## Anti-patterns

```go
require.Len(t, errs, 3)                                  // count instead of content
assert.ElementsMatch(t, []string{"email", "age"}, keys)  // projection + no order
require.NotEmpty(t, errs)                                // "something happened"
assert.Contains(t, res, "already exists")                // substring of a JSON contract
assert.Equal(t, int64(1), count)                         // DB count instead of records
assert.Equal(t, ErrRequired, errs[0].Reason)             // production supplies the answer
assert.Equal(t, want, validationTableValues(t, err))     // unwrap helper hides the payload
for i := range got { assert.Equal(t, i*2, got[i]) }      // test re-implements the algorithm
```

## Workflow

1. Read the function under test: return type, field order, exact strings, JSON shape.
2. Write `want` **by hand** from the spec — do not paste from a debugger or a failing run.
3. One primary equality assert per case (plus `require.NoError` guards).
4. Run it. If it fails, decide which side is wrong. Fix `want` or fix production — never weaken the assert.
5. Sanity check: break one field in production; the test must fail.

## Checklist

- [ ] No production function, constant, or enum appears inside `want`
- [ ] Every value in `want` is a literal typed by hand
- [ ] One full-value equality assert per case; no `Contains` / `Len` / `NotEmpty` as the main check
- [ ] HTTP bodies compared as complete JSON, plus status code
- [ ] DB assertions compare records, not counts
- [ ] Error messages and error payloads asserted in full
- [ ] Slice order pinned when production is deterministic; `nil` expected as `nil`
- [ ] Expectations written inline — no shared builder, unwrap helper, or fixture holding the answer
- [ ] Non-deterministic fields removed by name, not by loosening the comparison

## Why (references)

- [Testing on the Toilet: Tests Too DRY? Make Them DAMP!](https://testing.googleblog.com/2019/12/testing-on-toilet-tests-too-dry-make.html) — duplication in tests buys readability.
- [Tautological Tests](https://randycoulman.com/blog/2016/12/20/tautological-tests/) — a test that re-uses the implementation verifies nothing.
- [Obscure Test](http://xunitpatterns.com/Obscure%20Test.html), [Mystery Guest](http://xunitpatterns.com/Mystery%20Guest.html), [Assertion Roulette](http://xunitpatterns.com/Assertion%20Roulette.html) — xUnit Test Patterns smells this skill exists to prevent.
- [Go Wiki: Test Comments](https://go.dev/wiki/TestComments) — table-driven tests, `want`/`got` naming, `cmp.Diff` as `(-want +got)`.
