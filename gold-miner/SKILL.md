---
name: gold-miner
description: Generate beginner-friendly static HTML documentation for unfamiliar features by tracing real code. Use when a user asks to understand, document, 梳理, 反向分析, explain, onboard, or reverse-engineer a feature, API, command, UI flow, service behavior, data flow, or legacy requirement from an existing codebase.
---

# Gold Miner

Gold Miner turns a vague feature question into concrete, code-backed HTML docs
for junior developers. It mines the repository for entrypoints, data movement,
branches, examples, return values, and side effects, then writes a navigable doc
folder for the requested feature.

## Core Workflow

1. Resolve the project root from the user's path, otherwise use
   `git rev-parse --show-toplevel`, otherwise the current directory.
2. Extract the target feature name from the prompt. Create a stable
   lowercase slug such as `login`, `order-export`, or `image-generation`.
3. Resolve the docs root:
   - If the user specifies an output directory, use that directory.
   - Otherwise use `<project-root>/doc`.
   - Always create the feature directory inside it:
     `<docs-root>/<feature-slug>/`.
4. Inspect before writing. Search routes, controllers, handlers, commands,
   pages/components, UI strings, tests, config, schemas, migrations, models,
   queue jobs, RPC clients, SDK calls, and domain symbols. Prefer `rg`,
   `rg --files`, language servers, framework route lists, and test names over
   guessing.
5. Build a code evidence map with file paths, line numbers, symbol names,
   callers/callees, data stores, external services, and branch conditions.
6. Read `references/documentation-rubric.md` before drafting the docs.
7. Generate static HTML docs using `assets/templates/` as the base style and
   page structure. Copy `shared.css` into the feature doc folder as `style.css`.
8. Verify every important claim against code. If a detail cannot be confirmed,
   mark it explicitly as unknown and explain what code was checked.

## Required Output

Write these files at minimum:

- `index.html`: navigation, feature summary, reading order, and source map.
- `01-overview.html`: beginner-friendly mental model, purpose, and glossary.
- `02-entrypoints.html`: all confirmed feature entrypoints, triggers, inputs,
  validation, permissions, and return shapes.
- `03-flow-and-data.html`: step-by-step execution flow, data flow, state
  changes, persistence, side effects, and errors.
- `04-examples.html`: concrete examples with mock inputs, function/API calls,
  important branch cases, and expected outputs.

Add more numbered pages when useful, for example `05-debugging.html`,
`06-tests.html`, or `07-open-questions.html`. Keep the index links in sync.

## Documentation Rules

- Write for a new graduate developer who has never seen the codebase.
- Explain terms before using them heavily. Prefer concrete nouns over vague
  summaries.
- Include source evidence beside meaningful behavior: file path, line number,
  symbol, and why that code matters.
- Cover entrypoints, input parameters, execution process, data movement,
  return values, errors, logs, metrics, external calls, and side effects.
- Include at least one complete mock example. If the feature has multiple
  meaningful branches, include one example per branch.
- Show what function, endpoint, command, or UI event is called, what data is
  passed, what internal functions run, and what result is produced.
- Do not invent behavior. If code is ambiguous, say so and list the evidence
  that creates the ambiguity.
- Prefer diagrams and tables when they make the flow easier to scan, but keep
  the final artifact static HTML with local CSS only.

## Investigation Hints

Use a widening search pattern:

1. Search the exact feature wording and likely aliases from the prompt.
2. Search user-facing text, route names, API paths, command names, enum values,
   event names, permission names, database columns, and test descriptions.
3. Trace inward from entrypoints to services, repositories, models, external
   clients, serializers, and response builders.
4. Trace outward from core domain symbols to routes, jobs, schedulers, tests,
   and UI callers.
5. Compare tests and production code to discover branch behavior and examples.

When multiple possible features match, briefly list candidates with evidence
and ask the user to choose before generating docs.

## HTML Templates

Use these bundled resources:

- `assets/templates/index.template.html`: navigation page structure.
- `assets/templates/page.template.html`: numbered content page structure.
- `assets/templates/shared.css`: shared visual style.

Replace template placeholders with final content. Keep all links relative inside
the feature directory. Do not require a build step, JavaScript framework, or
network assets.
