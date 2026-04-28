---
description: 'C# coding standards. Use when writing or reviewing C# code. Covers nullable references, async/await, records, pattern matching, LINQ, and naming conventions.'
applyTo: '**/*.cs, **/*.razor, **/*.razor.cs'
---

# C# Code Standards

## Project Setup

- Target `net9.0` (or the project's specified TFM) — check `*.csproj`
- Enable `<Nullable>enable</Nullable>` and `<ImplicitUsings>enable</ImplicitUsings>`
- Enable `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` in CI
- Use file-scoped namespaces: `namespace MyApp.Feature;`

## Type Design

- Prefer **records** for DTOs, value objects, and command/query models
- Prefer **record structs** for small value types (coordinates, money amounts)
- Use **primary constructors** (C# 12+) for concise DI and initialization
- Use `required` properties for mandatory non-nullable fields
- Use **interfaces** for all public abstractions injected via DI
- Avoid `abstract` base classes when an interface suffices

## Nullable Reference Types

- Annotate all reference types — `string` means non-null, `string?` means nullable
- Use `ArgumentNullException.ThrowIfNull(param)` for null guards at method entry
- Use `!` (null-forgiving) only when you can provably prove non-null; add a comment
- Do not suppress `CS8600`–`CS8629` warnings with `#pragma` — fix them

## Async / Await

- Every async method returns `Task`, `Task<T>`, `ValueTask`, or `ValueTask<T>`
- Never `async void` except for event handlers — use `async Task` and call-site `await`
- Always accept and forward `CancellationToken ct` in async public methods
- Use `ConfigureAwait(false)` in libraries; omit in application/Blazor code
- Do not use `.Result`, `.Wait()`, or `GetAwaiter().GetResult()` — it causes deadlocks

## Pattern Matching

- Prefer `switch` expressions over `if/else if` chains for multiple conditions
- Use **list patterns** (`[first, .., last]`) for sequence matching
- Use **property patterns** (`is { Name: "admin", Role: Role.Admin }`) over field access chains
- Use **positional patterns** with records

## LINQ

- Chain method syntax for most queries; use query syntax for multi-join or `let` clauses
- Do not materialize unnecessarily — keep `IQueryable` lazy until the last moment
- Use `DistinctBy`, `MinBy`, `MaxBy`, `Chunk` (LINQ 6+) over manual workarounds
- Avoid `.Count()` on `ICollection<T>` or `IList<T>` — use `.Count` property

## Error Handling

- Use typed domain exceptions for expected business errors
- Use `Result<T, TError>` pattern for operations that can fail predictably
- Use `ArgumentException.ThrowIfNullOrEmpty()`, `ArgumentOutOfRangeException.ThrowIfNegative()` for guard clauses
- Never catch `Exception` and swallow it — at minimum log and rethrow

## Naming Conventions

- **PascalCase**: classes, records, interfaces, enums, methods, properties, events
- **camelCase**: local variables, parameters, private fields
- **\_camelCase**: private instance fields (prefix with `_`)
- **SCREAMING_SNAKE_CASE**: constants (`const`) and static readonly fields
- Interfaces: prefix with `I` (`IUserRepository`)
- Async methods: suffix with `Async` (`GetUserAsync`)
- Avoid abbreviations — `userId` not `uid`, `cancellationToken` not `ct` in public APIs

## Formatting

- Use `dotnet format` — enforce via CI
- 4-space indentation (not tabs)
- Opening brace on the same line for expressions, new line for type/method declarations
- `using` declarations (`using var x = ...`) over `using` blocks where scope is clear
