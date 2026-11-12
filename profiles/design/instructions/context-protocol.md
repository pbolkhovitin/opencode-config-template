# Context protocol

- At task start read `context/INDEX.md`, then `context/current.md`.
- At task start, recall only memories relevant to the current objective; do not
  inject the whole memory store.
- Keep `context/current.md` current: Objective, Constraints, Decisions, Files,
  Next step, Open questions. Update it after each milestone.
- Put durable decisions in `context/decisions.md`; one line per decision.
- Put long details in a topic file under `context/` or `context/playbooks/`
  and add one line to `INDEX.md`. Do not load `archive/*` unless the index
  points to a specific file.
- Prefer `grep` + `read` with `offset`/`limit` over reading whole files.
- When compressing, preserve objective, decisions, touched files, next step,
  and links to the relevant context files.
- Use subagents for isolated work so long logs stay out of the main context.
