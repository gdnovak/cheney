# Memory Workflow: Weekly Operations

Purpose: keep `memory/` reliable for fast resume and clear decision history with minimal overhead.

## Weekly Cadence

Run once per week (or at major checkpoint):

1. Create/update weekly summary note in `memory/projects/`:
   - `week-YYYY-WW-summary.md`
2. Ensure new decisions are captured in `memory/decisions/`.
3. Update `memory/index.md` active notes list.
4. Run lexical index helper and spot-check note graph links.

## Commands

List/inspect notes:

```bash
rg --files memory | sort
scripts/memory_index.sh memory
rg -n "^\[\[|^id:|^tags:" memory
```

Backlink checks:

```bash
rg -n "\[\[dec-|\\[\\[proj-|\\[\\[week-" memory
```

## Minimum Weekly Acceptance

1. At least one current weekly summary exists.
2. Any new high-impact decision has a decision note.
3. `memory/index.md` links to active project + latest weekly summary + latest key decisions.
4. `scripts/memory_index.sh memory` runs without errors.

## Suggested Note Hygiene

1. Keep frontmatter fields present (`id`, `title`, `type`, `tags`, `created`, `updated`, `scope`, `status`).
2. Prefer concise bullets over long prose for operational notes.
3. Link every weekly summary to active project and relevant decisions.
