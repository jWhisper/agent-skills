# Draw Tea Workflow

Use this sequence before implementation starts.

## Project Root

1. Resolve the project root from the user's path.
2. If no path is provided, use `git rev-parse --show-toplevel`.
3. If that fails, use the current directory.

Create preparation files in the project root unless the user explicitly asks for
another directory.

## Requirement Analysis

Requirements may come from the user's message, an attached document, a local
file path, or a link.

1. Gather the requirement source before planning.
2. For attached or local documents, read the document content first and extract
   the user's goal, constraints, acceptance expectations, and unresolved
   questions.
3. For links, prefer querying through Omnibus MCP tools when they are available.
   Use the linked content as source material rather than relying on the URL
   title, memory, or guesswork. If Omnibus is unavailable or cannot access the
   link, use the best available fallback and record the access limitation as an
   assumption or open question.
4. Restate the requirement in plain language.
5. Identify goals, non-goals, constraints, likely affected areas, and unknowns.
6. Inspect the repository only enough to make the plan concrete. Prefer `rg`,
   `rg --files`, existing docs, tests, routes, schemas, and config over guesses.
7. Record facts separately from assumptions.

## Disagreement Gate

Stop and discuss with the user before finalizing files when there is a real
choice or conflict, including:

- conflicting requirements
- multiple viable architectures with meaningful tradeoffs
- unclear product behavior
- risky data migration scope
- unclear external API contracts
- missing acceptance criteria
- a plan that would require broad or destructive changes

If a detail is unknown but not blocking, record it as an assumption or open
question in `architecture.md` instead of inventing certainty.

## File Creation

If a required file already exists, read it first and preserve unrelated content.
Prefer adding or updating a clearly named section over replacing the whole file.

Allowed preparation files:

- `CLAUDE.md`
- `AGENTS.md`
- `architecture.md`
- `task.json`
- `progress.md`
- `init.sh`
- `run-automation.sh`

After writing the files, show the方案 and stop.
