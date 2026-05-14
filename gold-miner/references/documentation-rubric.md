# Gold Miner Documentation Rubric

Use this rubric before writing and before final verification. The output should
feel like a patient senior engineer walking a new graduate through unfamiliar
code with receipts.

## Required Evidence

Every major behavior should cite code evidence:

- File path and line number.
- Symbol name, route, command, component, SQL table, config key, or test name.
- Why the evidence matters to the feature.
- Whether the evidence is direct implementation, caller, test coverage, config,
  or inferred context.

Avoid claims such as "probably", "usually", or "seems to" unless the docs label
the statement as an inference and explain the source of uncertainty.

## Required Topics

Cover these topics when the codebase contains them:

- Feature purpose and user/business outcome.
- Entry triggers: API routes, UI actions, commands, scheduled jobs, message
  consumers, hooks, or library calls.
- Inputs: parameters, request body, query string, headers, context values,
  config, database rows, files, environment variables, and defaults.
- Validation and authorization: required permissions, schema checks, guard
  clauses, limits, and rejected cases.
- Flow: ordered execution steps from entrypoint to return value.
- Data flow: transformations, DTOs, models, database reads/writes, cache usage,
  queues, events, and external API calls.
- Outputs: response body, rendered UI state, generated files, database changes,
  emitted messages, logs, metrics, and error shapes.
- Branches: success path, missing data, invalid input, permission failure,
  external service failure, timeout, retry, fallback, and no-op path.
- Tests: existing unit, integration, e2e, or fixture examples that confirm
  behavior.
- Debugging: where a junior developer should put breakpoints or add logs first.

## Example Requirements

Each example must be concrete enough to replay mentally:

- Use realistic mock input data.
- Name the exact entrypoint being invoked.
- Show the important intermediate data after validation or transformation.
- Show the final return value or side effect.
- Link the example to the branch or condition it demonstrates.

For generation-style features, include sample source data, the called function
or endpoint, any template/config values, and the generated result. For data
mutation features, include before/after records. For UI flows, include the user
action, resulting client state, network request, and rendered result.

## HTML Quality

The docs must be plain static HTML:

- `index.html` links to every numbered page.
- Numbered pages use predictable names such as `01-overview.html`.
- Every page links back to `index.html`.
- Tables are used for parameters, return values, branch cases, and source maps.
- Code blocks are escaped HTML and preserve indentation.
- Long pages include short section headings and anchors.
- The visual style is readable without external fonts, CDNs, or scripts.

## Final Self-Check

Before reporting completion, confirm:

- The feature directory exists under the correct docs root.
- `index.html` and all linked numbered pages exist.
- The docs mention entrypoints, inputs, flow, data movement, returns, errors,
  side effects, and examples.
- At least one complete mock example exists.
- Branch examples exist when code has branch behavior.
- Important claims include source evidence.
- No generated page depends on external network resources.
