---
name: diagnose
description: 'Six-phase disciplined debugging loop: build a feedback loop first, then reproduce, hypothesise, instrument, fix, and add a regression guard. Use when a test fails, a bug is reported, or behavior is unexpected and random guessing has not worked.'
---

# Diagnose

## Overview

Debugging is a feedback loop problem. The single most important insight: **if you don't have a fast, deterministic pass/fail signal, no amount of staring at code will save you.** Build that signal first — everything else follows.

This skill uses a six-phase loop. You will cycle through it more than once on hard bugs.

```
Build Feedback Loop ──→ Reproduce ──→ Hypothesise ──→ Instrument ──→ Fix ──→ Cleanup
        ↑                                                                        |
        └────────────────────────────── (if not solved) ─────────────────────────┘
```

## When to Use

- A test is failing and you don't know why
- A bug was reported and you cannot reproduce it yet
- Behavior changed after a refactor and the cause is unclear
- CI is failing but it passes locally
- You've been staring at code for more than 10 minutes without progress

**When NOT to use:** You already know the root cause — just fix it. Use `code-review` for proactive review. Use `performance-optimization` for perf issues without errors.

## The Six Phases

### Phase 1 — Build a Feedback Loop

Before anything else, create a **fast, deterministic, automated** way to see pass vs fail.

**Target: under 10 seconds per iteration.**

Questions to answer:

- Can I run a single test that directly exercises the failure?
- If not, can I write one?
- Is the failure deterministic or flaky? (If flaky: fix flakiness first — a non-deterministic signal is worse than no signal)
- Can I reduce the feedback cycle time? (disable unrelated tests, seed the DB, mock slow dependencies)

**Output:** A command you can run repeatedly that shows RED when broken and GREEN when fixed.

```bash
# Examples
npm test -- --testPathPattern=auth.test.ts
pytest tests/test_auth.py::test_login_timeout -x
go test ./pkg/auth/... -run TestLoginTimeout -v
dotnet test --filter "FullyQualifiedName~LoginTimeout"
```

Do not proceed until you have this command.

### Phase 2 — Reproduce

Confirm you can trigger the exact failure with your feedback loop command.

**Checklist:**

- [ ] Run the failing test/reproduction case — does it fail reliably?
- [ ] Note the exact error message and stack trace
- [ ] Note the environment: OS, runtime version, env vars, data state
- [ ] If it only fails in CI: compare CI environment with local environment line by line
- [ ] If it only fails intermittently: add timestamps, check for race conditions, try `--runInBand`

**Record:**

```
FAILURE: [exact error message]
STACK:   [relevant frames only]
ENV:     [runtime, OS, key env vars]
WHEN:    [always / only in CI / intermittent — N/M runs]
```

Do not proceed until the failure is deterministic.

### Phase 3 — Hypothesise

Generate **multiple** hypotheses before testing any of them.

**Rules:**

- Write down at least 3 hypotheses before touching code
- Order by likelihood (most likely first)
- Each hypothesis must be **falsifiable** — it must predict an observable outcome
- Do not conflate hypothesis with fix

**Template:**

```
H1: [Description] — If true, I expect to see [observable outcome] when I [action]
H2: [Description] — If true, I expect to see [observable outcome] when I [action]
H3: [Description] — If true, I expect to see [observable outcome] when I [action]
```

**Common categories to consider:**

- Timing / async race condition
- State mutation (shared mutable state, singleton, global)
- Environment difference (env var, file path, locale, timezone)
- Data shape mismatch (null, undefined, wrong type)
- Off-by-one / boundary condition
- Dependency version mismatch
- Caching (stale cache, hot reload not firing)

### Phase 4 — Instrument

Test your hypotheses cheapest-first. Add **minimal, targeted** instrumentation — only what reveals whether a hypothesis is true.

**Order of instrumentation cost (cheapest first):**

1. Read existing logs, stack traces, error messages
2. Add a single `console.log` / `print` / `fmt.Println` at the exact site
3. Run the feedback loop command with `--verbose` / `-v`
4. Add a debugger breakpoint at the exact site
5. Write an intermediate assertion in the test
6. Add structured logging and query it
7. Reproduce in a minimal isolated environment

**Rules:**

- Test one hypothesis at a time — don't add 5 logs at once
- Remove instrumentation that disproved its hypothesis immediately
- If all hypotheses are disproved: go back to Phase 3 with new information

**Record each experiment:**

```
TESTED: H1 — added log at auth/middleware.ts:42
RESULT: Value was null, not undefined as expected → H1 DISPROVED
NEXT:   Test H2
```

### Phase 5 — Fix

Once a hypothesis is confirmed, fix at the **root cause**, not the symptom.

**Checklist:**

- [ ] Does the fix address the root cause or paper over the symptom?
- [ ] Run the feedback loop command — does it turn GREEN?
- [ ] Run the full test suite — does anything else break?
- [ ] Does the fix handle the edge cases that caused the bug?
- [ ] Is the fix the simplest correct solution?

**Anti-patterns to avoid:**

- Adding a `try/catch` to swallow the error instead of fixing the cause
- Adding a special case for the buggy input instead of validating earlier
- Changing the test to match wrong behavior

### Phase 6 — Cleanup

Prevent regression and document for the next person.

**Checklist:**

- [ ] Add or update a test that would have caught this bug (regression test)
- [ ] Remove all debug instrumentation (logs, breakpoints, commented-out code)
- [ ] Update `CONTEXT.md` if this bug revealed a missing concept or constraint
- [ ] Add a code comment at the fix site if the reason is non-obvious
- [ ] Consider: is this pattern of bug likely elsewhere? If so, search and fix proactively

**Regression test template:**

```
// Regression: [brief description of the bug]
// See: [issue link if available]
it('should [expected behavior] when [condition that caused the bug]', () => {
  // arrange: the minimal setup that triggers the original bug
  // act: the operation that was failing
  // assert: the correct outcome
});
```

## Common Rationalizations to Reject

- _"I'll just try changing X and see what happens"_ — No. Hypothesise first or you learn nothing.
- _"The test is wrong, not the code"_ — Maybe. But prove it, don't assume it.
- _"It must be a framework bug"_ — Almost never. Check your code first.
- _"It works on my machine"_ — The environment difference IS the bug. Find it.
- _"I'll just catch the exception"_ — Only if you are deliberately handling a known error condition.

## Verification

The session is complete when:

- [ ] Feedback loop command runs GREEN
- [ ] Full test suite passes
- [ ] A regression test exists that would catch this bug
- [ ] Debug instrumentation is removed
- [ ] `CONTEXT.md` updated if a domain concept was missing
