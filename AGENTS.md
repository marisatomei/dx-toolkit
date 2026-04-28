# AGENTS.md — DX Toolkit

This file helps AI agents understand the available agents and how to use them.

## Agent Categories

### General-Purpose (9)

| Agent                   | Purpose                                          |
| ----------------------- | ------------------------------------------------ |
| `bug-fixer`             | Diagnose and fix bugs from issue descriptions    |
| `feature-implementer`   | Implement features from specs or issues          |
| `refactorer`            | Improve code structure without changing behavior |
| `test-writer`           | Generate comprehensive tests for existing code   |
| `docs-updater`          | Update documentation to match code changes       |
| `docs-humanizer`        | Rewrite robotic docs to sound natural            |
| `security-fixer`        | Find and fix security vulnerabilities            |
| `performance-optimizer` | Profile and optimize slow code                   |
| `dependency-updater`    | Update dependencies safely                       |

### Technology-Specialized (38+)

| Agent                         | Domain                           |
| ----------------------------- | -------------------------------- |
| `elixir-expert`               | Elixir / OTP                     |
| `phoenix-expert`              | Phoenix Framework                |
| `typescript-expert`           | TypeScript                       |
| `nextjs-expert`               | Next.js                          |
| `react-expert`                | React                            |
| `react-native-expert`         | React Native                     |
| `expo-expert`                 | Expo                             |
| `postgresql-expert`           | PostgreSQL                       |
| `supabase-expert`             | Supabase                         |
| `docker-expert`               | Docker / containers              |
| `wordpress-expert`            | WordPress                        |
| `design-systems-expert`       | Design systems / UI libraries    |
| `frontend-expert`             | Frontend architecture            |
| `backend-expert`              | Backend architecture             |
| `web-development-expert`      | Full-stack web                   |
| `conventional-commits-expert` | Commit message standards         |
| `tdd-expert`                  | Test-driven development          |
| `bdd-expert`                  | Behavior-driven development      |
| `payments-expert`             | Payment integrations             |
| `python-expert`               | Python                           |
| `go-expert`                   | Go                               |
| `rust-expert`                 | Rust                             |
| `swift-expert`                | Swift / iOS                      |
| `kotlin-expert`               | Kotlin / Android                 |
| `flutter-expert`              | Flutter / Dart                   |
| `rails-expert`                | Ruby on Rails                    |
| `vue-expert`                  | Vue.js / Nuxt                    |
| `angular-expert`              | Angular                          |
| `svelte-expert`               | Svelte / SvelteKit               |
| `graphql-expert`              | GraphQL                          |
| `terraform-expert`            | Terraform / IaC                  |
| `csharp-expert`               | C# / .NET                        |
| `aspnetcore-expert`           | ASP.NET Core backend             |
| `blazor-expert`               | Blazor frontend (Server/WASM)    |
| `deepstream-expert`           | NVIDIA DeepStream SDK            |
| `deepstream-plugin-expert`    | DeepStream C++ plugins           |
| `deepstream-inference-expert` | TensorRT / nvinfer inference     |
| `tao-toolkit-expert`          | NVIDIA TAO Toolkit / fine-tuning |

### Content-Specialized (2)

| Agent              | Domain                      |
| ------------------ | --------------------------- |
| `seo-writer`       | SEO-optimized content       |
| `marketing-expert` | Marketing copy and strategy |

## How to Use Agents

### In GitHub (assign to issues)

```
@bug-fixer Please fix the login timeout issue described above.
```

### In VS Code (Copilot Chat)

```
@feature-implementer Implement the user profile page based on the spec in #42.
```

### With Skills

Agents can reference skills for structured workflows:

```
@feature-implementer Use /explore to define this feature, then /outline to break it into tasks, then /develop to implement.
```

## Development Lifecycle Integration

Agents map to lifecycle phases based on their purpose:

- **EXPLORE**: `feature-implementer` (with `/explore`), `docs-updater`
- **OUTLINE**: `feature-implementer` (with `/outline`)
- **DEVELOP**: `feature-implementer`, `*-expert` agents (domain-specific)
- **CHECK**: `test-writer`, `tdd-expert`, `bdd-expert`, `bug-fixer`
- **POLISH**: `refactorer`, `security-fixer`, `performance-optimizer`
- **LAUNCH**: `docs-updater`, `docs-humanizer`, `conventional-commits-expert`, `dependency-updater`
