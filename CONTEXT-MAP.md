# Context Map

## Contexts

- [Matt Pocock Skills](./CONTEXT.md) — the shipped skill set and the issue-tracker language its flows run on
- [Personal Skills](./skills/personal/CONTEXT.md) — skills tied to my own machine, and the vocabulary they use

## Relationships

- **Personal Skills → Matt Pocock Skills**: personal skills are packaged and linked exactly like promoted ones (same `SKILL.md` shape, same `agents/openai.yaml` sidecar, same `scripts/link-skills.sh` linking), but are excluded from the top-level `README.md`, `.claude-plugin/plugin.json`, `docs/`, and the `ask-matt` router. The two vocabularies do not overlap — nothing in the personal context refers to Issues or Triage roles.
