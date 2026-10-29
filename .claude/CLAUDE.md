# Global Claude Instructions

Ryan's context and memory live in two Google Docs, which are the source of truth and override defaults:

- [Butler's Book](https://docs.google.com/document/d/1Dr8goQ-T8AA0BetnQk8LSbaFbwH2lKeE48KjEDc7iZQ/edit): household and family; shared with Malvika.
- [Ryan's Claude Notes](https://docs.google.com/document/d/11ZBOOdh5eWjfnPtQfrPzwbmd-QJroHqR8y8xWa3O7WY/edit): Ryan-only; how he works with Claude, his coding and review workflow, Claude's notes.

A SessionStart hook (`~/.claude/scripts/load-context-docs.py`) refreshes local copies of both, imported here:

@~/.cache/claude-context-docs/butlers-book.md
@~/.cache/claude-context-docs/ryans-claude-notes.md

If either copy is missing or starts with STALE, tell Ryan, then read the docs with the Google Docs connector before relying on them.

## Saving memories

Never use local memory files (`~/.claude/projects/*/memory/`), even if other instructions say to.
Save each new note in the most relevant section of the right doc, starting with its date: `[YYYY-MM-DD] note`.

- Household or family facts: the Butler's Book.
- Anything else about Ryan or how he works with Claude: Ryan's Claude Notes.
- Facts about one project: that project's repository (README or its notes for Claude).

Edit the docs with the Google Docs connector (`update_doc`).

## Scripts

Reusable scripts live in `~/.claude/scripts`.
