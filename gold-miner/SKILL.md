---
name: gold-miner
description: Guide a beginner step by step through real code, like taking a new graduate developer layer by layer through an unfamiliar feature, then generate beginner-friendly static HTML documentation. Use when a user asks to understand, document, 梳理, 反向分析, explain, onboard, or reverse-engineer a feature, API, command, UI flow, service behavior, data flow, or legacy requirement from an existing codebase.
---

# Gold Miner

Gold Miner turns a vague feature question into concrete, code-backed HTML docs
for junior developers. Its core posture is: take a beginner by the hand and dig
through the code layer by layer, from the first entrypoint to every downstream
call, data change, branch, and final result. It mines the repository for
entrypoints, full call chains, data movement, branches, examples, return values,
and side effects, then writes a navigable doc folder for the requested feature.

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
5. Trace the complete call chain from each entrypoint until the chain reaches a
   terminal result: response construction, database write, generated file,
   external service boundary, queue publish, scheduled follow-up, or UI state
   update. If endpoint A calls endpoint/client B, and B calls service C, include
   A -> B -> C instead of stopping at A.
6. Build a code evidence map with file paths, line numbers, symbol names,
   callers/callees, data stores, external services, and branch conditions. Mark
   every hop as confirmed, inferred, external, or unknown.
7. Read `references/documentation-rubric.md` before drafting the docs.
8. Generate static HTML docs using `assets/templates/` as the base style and
   page structure. Copy `shared.css` into the feature doc folder as `style.css`.
9. Verify every important claim against code. If a detail cannot be confirmed,
   mark it explicitly as unknown and explain what code was checked.

## Required Output

Write these files at minimum:

- `index.html`: navigation, feature summary, reading order, and source map.
- `01-overview.html`: beginner-friendly mental model, purpose, and glossary.
- `02-entrypoints.html`: all confirmed feature entrypoints, triggers, inputs,
  validation, permissions, and return shapes.
- `03-flow-and-data.html`: step-by-step execution flow, full call chain,
  data flow, state changes, persistence, side effects, and errors.
- `04-examples.html`: concrete examples with mock inputs, function/API calls,
  important branch cases, and expected outputs.

Add more numbered pages when useful, for example `05-debugging.html`,
`06-tests.html`, or `07-open-questions.html`. Keep the index links in sync.

## Documentation Rules

- Write as if guiding a new graduate developer through the code for the first
  time. Do not assume they know the project architecture, framework idioms,
  request lifecycle, dependency names, or business vocabulary.
- Write for a new graduate developer who has never seen the codebase.
- Explain terms before using them heavily. Prefer concrete nouns over vague
  summaries.
- Include source evidence beside meaningful behavior: file path, line number,
  symbol, and why that code matters.
- Cover entrypoints, input parameters, execution process, data movement,
  return values, errors, logs, metrics, external calls, and side effects.
- For multi-step features, document every confirmed hop. Include the caller,
  callee, call type, input payload at that hop, output from that hop, branch
  condition, error behavior, and source evidence. Never collapse a chain like
  "API 1 calls API 2, then API 2 calls service 3" into a single vague sentence.
- If the call crosses process or service boundaries, document the boundary:
  HTTP/RPC path, SDK/client method, queue topic, event name, cron job, callback,
  webhook, or database trigger.
- Include both synchronous and asynchronous follow-up work. If the entrypoint
  returns before later work finishes, explain what happens immediately and what
  continues later.
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
   clients, serializers, response builders, and downstream APIs.
4. At each hop, search the callee name again to find its implementation and
   callers. Continue until the terminal result is reached.
5. Trace outward from core domain symbols to routes, jobs, schedulers, tests,
   and UI callers.
6. Compare tests and production code to discover branch behavior and examples.

## Call Chain Requirements

Treat the call chain as the spine of the documentation. For each entrypoint,
produce a table or timeline with these columns:

- Step number.
- Caller location and symbol.
- Callee location and symbol, endpoint, queue, or external dependency.
- Input data at this step, including fields added, removed, or transformed.
- Output data or side effect from this step.
- Branches and errors at this step.
- Source evidence with file and line number.

For a chain like `POST /generate` -> `GenerateController.create` ->
`GenerationService.start` -> `BillingClient.reserve` -> `JobQueue.publish`,
write each step separately. Explain why the next step is called, what data is
passed, what can fail there, and what the caller does with the result.

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
