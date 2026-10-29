# Global Claude Instructions

Ryan's context and memory live in two Google Docs, which are the source of truth and override defaults:

- [Butler's Book](https://docs.google.com/document/d/1Dr8goQ-T8AA0BetnQk8LSbaFbwH2lKeE48KjEDc7iZQ/edit): household and family; shared with Malvika.
- [Ryan's Claude Notes](https://docs.google.com/document/d/11ZBOOdh5eWjfnPtQfrPzwbmd-QJroHqR8y8xWa3O7WY/edit): Ryan-only; how he works with Claude, his coding and review workflow, Claude's notes.

A SessionStart hook (`~/.claude/scripts/load-context-docs.py`) refreshes local copies of both, imported here:

@~/.cache/claude-context-docs/butlers-book.md
@~/.cache/claude-context-docs/ryans-claude-notes.md

If either copy is missing or starts with STALE, tell Ryan, then read the docs with the Google Docs connector before relying on them.

## Saving memories

Keep using Claude Code's built-in memory, then move each new memory into the docs right away:

1. Save the memory file as usual.
2. Add it to the most relevant section of the right doc with the Google Docs connector (`update_doc`), starting with its date: `[YYYY-MM-DD] note`.
   - Household or family facts: the Butler's Book.
   - Anything else about Ryan or how he works with Claude: Ryan's Claude Notes.
   - Facts about one project: that project's repository (README or its notes for Claude).
3. Once the doc update succeeds, delete the memory file and its line in `MEMORY.md`.
   If it fails, keep the file and tell Ryan.

If the session-start hook lists memory files waiting to be moved, move them the same way.

## Scripts

Reusable scripts live in `~/.claude/scripts`.
