---
name: tdd
description: 'Test-driven development using the red-green-refactor loop. Enforces vertical slices (one test, one implementation, repeat) over horizontal slicing (all tests then all code). Use when building new features, fixing bugs with regression tests, or establishing TDD in a codebase.'
---

# TDD

## Overview

TDD is a **development discipline**, not a testing strategy. The goal is not test coverage — it is **design feedback**. Writing a test before code forces you to design the interface before the implementation.

The loop:

```
RED ──→ GREEN ──→ REFACTOR ──→ RED ──→ ...
```

1. **RED:** Write a failing test for the smallest unit of behavior
2. **GREEN:** Write the minimum code to make it pass (no more, no less)
3. **REFACTOR:** Improve the code without changing behavior (tests stay green)

Repeat for every behavior.

## When to Use

- Building a new feature from scratch
- Fixing a bug (write the regression test first)
- Refactoring a module (get tests green first, then refactor)
- Onboarding to an unfamiliar codebase (tests reveal intent)

**When NOT to use:** Exploratory prototyping where the right API is completely unknown. Write a throwaway spike first, then TDD the real implementation.

## The Core Rule: Vertical Slices Only

**Anti-pattern — horizontal slicing:**

```
Day 1: Write ALL tests for the feature
Day 2: Write ALL implementation
Day 3: Fix everything that's broken
```

This defeats TDD. You get no design feedback. You discover interface problems too late.

**Correct — vertical slicing:**

```
Hour 1: RED   — write test for behavior A
Hour 1: GREEN — implement behavior A (only what's needed)
Hour 1: REF   — clean up
Hour 2: RED   — write test for behavior B
Hour 2: GREEN — implement behavior B (may extend what you wrote)
Hour 2: REF   — clean up
...
```

Each vertical slice delivers working, tested behavior. The feature grows incrementally.

## The Tracer Bullet

Start with a **tracer bullet** — the thinnest possible end-to-end path through the feature that exercises the real integration points.

**What a tracer bullet is:**

- A test that exercises the full path from input to output
- Uses real implementations (no mocks) wherever possible
- May be slow — that's acceptable for the first test
- Proves the plumbing works before building the details

**What a tracer bullet is NOT:**

- An E2E test that tests every behavior (that comes after)
- A unit test that mocks everything except one class
- The happy path only — include the most likely error path

**Example tracer bullet sequence:**

```
1. POST /api/users creates a user and returns 201         ← tracer bullet
2. POST /api/users with duplicate email returns 409
3. POST /api/users with invalid email returns 400
4. POST /api/users sends welcome email
5. POST /api/users logs the creation event
```

Start with test 1. Don't write test 2 until test 1 is GREEN.

## The Loop in Practice

### RED Phase

Write a single test that:

- Tests **one behavior** (not one function)
- Has a clear, specific assertion
- Has a name that reads as a sentence: `should [behavior] when [condition]`
- Fails for the right reason (not a syntax error, not a missing import)

**Check before proceeding:**

- [ ] The test fails (RED) — if it passes without code, the test is wrong
- [ ] The failure message is the one you expected
- [ ] The test name clearly describes the intended behavior

```typescript
// Good: tests one behavior with a specific assertion
it('should return 409 when email already exists', async () => {
  await createUser({ email: 'test@example.com' })
  const response = await POST('/api/users', { email: 'test@example.com' })
  expect(response.status).toBe(409)
  expect(response.body.error).toBe('EMAIL_ALREADY_EXISTS')
})

// Bad: tests the implementation, not the behavior
it('should call UserRepository.findByEmail', async () => {
  // This test will survive wrong behavior as long as the method is called
})
```

### GREEN Phase

Write the **minimum code** to make the test pass. No more.

**Rules:**

- Do not write code for behaviors not yet tested
- Do not abstract prematurely — duplication is fine at this stage
- If you catch yourself writing code "just in case," stop
- The goal is GREEN, not perfect

**Check before proceeding:**

- [ ] The test is GREEN
- [ ] You haven't written code for untested behaviors
- [ ] The full test suite still passes (no regressions)

### REFACTOR Phase

With tests green, improve the code:

- Extract duplication into well-named abstractions
- Rename variables and functions to match domain vocabulary (see `CONTEXT.md`)
- Simplify control flow
- Move code to its correct location (wrong file/module is a code smell)

**Rules:**

- Tests must remain GREEN throughout refactoring — run them after every change
- Do not add new behavior during refactor (that's the next RED phase)
- Do not refactor speculatively — only remove duplication that actually exists

**Check before proceeding:**

- [ ] All tests still GREEN
- [ ] Code is simpler than before (fewer lines, better names, less duplication)
- [ ] No new abstractions added that aren't tested

## Test Design Principles

### Test behavior, not implementation

```typescript
// Tests behavior (survives refactoring)
expect(cart.total).toBe(150)

// Tests implementation (breaks on refactoring)
expect(cart.lineItems[0].calculateSubtotal).toHaveBeenCalled()
```

### One assertion per test (usually)

Multiple assertions are acceptable when they test the same behavior from different angles. They are not acceptable when they test different behaviors.

### Test the contract, not the internals

- Test public interfaces, not private methods
- Test inputs and outputs, not intermediate state
- Private methods are implementation details — if they need testing, they may need to be public

### Arrange-Act-Assert

```
// Arrange: set up state
const cart = new Cart()
cart.add({ id: 'SKU-1', price: 75, qty: 2 })

// Act: perform the operation
const total = cart.calculateTotal()

// Assert: verify the outcome
expect(total).toBe(150)
```

## Mocking Strategy

Mock at **boundaries** only:

- External network calls (HTTP, database, message queue)
- Time (`Date.now()`, `new Date()`)
- File system (when testing logic, not file operations)
- Third-party services

**Do NOT mock:**

- Your own modules — if you mock your own code, you test nothing
- Value objects and pure functions
- Simple data containers

## Regression Testing (Bug-Fix TDD)

When fixing a bug, write the regression test **before** the fix:

1. Understand the bug
2. Write a test that reproduces the bug (it will be RED)
3. Fix the bug (test turns GREEN)
4. Confirm the full suite passes

This guarantees the bug stays fixed. A bug without a regression test will return.

## Verification

A TDD session is healthy when:

- [ ] Every new behavior has at least one test
- [ ] No test was written after the code it tests (except regression tests)
- [ ] All tests pass
- [ ] Test names read as behavior specifications
- [ ] No test mocks your own modules
