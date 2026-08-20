# Global Claude Instructions

## Attribution — Claude vs. Ryan

Never attribute your (Claude's) words, comments, or actions to Ryan, or vice versa — in any writing (chat replies, drafts, PR comments, commit messages).
Even when writing content that will be posted from Ryan's account, refer to things Claude did as Claude's ("in the UX comments Claude drafted") and things Ryan did as Ryan's ("in Ryan's UX comments") — never "my" for something the other said or did.
When it's ambiguous who said or did something, say so explicitly rather than guessing.

## Scripting

Prefer scripts we've written in `~/.claude/scripts` and normal terminal commands (e.g. jq, cat, grep, awk, etc.) over writing custom python or node scripts as these always require approval and the former does not.
Feel free to suggest a new read-only tool to install that would prevent needing to write a custom script.

## JSON Analysis

When analyzing or querying JSON data, prefer `jq` over writing a Python script unless the transformation is complex enough that jq syntax would be harder to read.

## CSV/TSV Analysis

When reading or transforming CSV/TSV data, prefer `mlr` (Miller) over writing a Python script unless the transformation is too complex for miller syntax.

## XML/SVG/HTML Analysis

When querying or extracting from XML, SVG, or HTML, prefer `xmllint` (xpath queries) or `xmlstarlet` over writing a Python/Node script. Examples:
- Extract a specific element: `xmllint --xpath '//symbol[@id="list-ul"]' file.svg`
- Get an attribute value: `xmllint --xpath 'string(//element/@attr)' file.xml`

## Coding

Prefer clean, readable code.

Prefer early returns over ternaries in function return statements.
Instead of `return condition ? a : b`, write `if (condition) return a; return b;`.
Do NOT use early returns if they increase repetition — if the branches share significant trailing logic, use if/else to set a variable instead.
For nested ternaries in variable assignments, prefer if/else over nesting: `if (a) x = 1; else if (b) x = 2; else x = 3;` is clearer than `const x = a ? 1 : b ? 2 : 3`.
Simple single-level ternary variable assignments (`const x = condition ? a : b`) are fine when short and both branches are obvious.

Prefer flat if-chains over nested ifs.
When an outer condition is just a conjunction of inner ones, expand it into each branch instead of nesting.
Each case then states its own full condition and is readable in isolation without tracking outer context.
Example — instead of `if (a && b) { if (c) return x; return y; } if (a) return z;`, write `if (a && b && c) return x; if (a && b) return y; if (a) return z;`.

Prefer self-documenting code, such as using a variable name to document.
So instead of this (this is Understandability tops #2 below):
```ts
const hours = days * 24; // 24 hours in a day
```
do something like this:
```ts
const HOURS_PER_DAY = 24;
const hours = days * HOURS_PER_DAY;
```

Follow other rules for Clean Code (lifted from https://gist.github.com/wojteklu/73c6914cc446146b8b533c0988cf8d29):

Code is clean if it can be understood easily – by everyone on the team.
Clean code can be read and enhanced by a developer other than its original author.
With understandability comes readability, changeability, extensibility and maintainability.
_____________________________________

### General rules
1. Follow standard conventions.
2. Keep it simple stupid.
   Simpler is always better.
   Reduce complexity as much as possible.
3. Boy scout rule.
   Leave the campground cleaner than you found it.
4. Always find root cause.
   Always look for the root cause of a problem.

### Design rules
1. Keep configurable data at high levels.
2. Prefer polymorphism to if/else or switch/case.
3. Separate multi-threading code.
4. Prevent over-configurability.
5. Use dependency injection.
6. Follow Law of Demeter.
   A class should know only its direct dependencies.

### Understandability tips
1. Be consistent.
   If you do something a certain way, do all similar things in the same way.
2. Use explanatory variables.
3. Encapsulate boundary conditions.
   Boundary conditions are hard to keep track of.
   Put the processing for them in one place.
4. Prefer dedicated value objects to primitive type.
5. Avoid logical dependency.
   Don't write methods which works correctly depending on something else in the same class.
6. Avoid negative conditionals.

### Names rules
1. Choose descriptive and unambiguous names.
2. Make meaningful distinction.
3. Use pronounceable names.
4. Use searchable names.
5. Replace magic numbers with named constants.
6. Avoid encodings.
   Don't append prefixes or type information.

### Functions rules
1. Small.
2. Do one thing.
3. Use descriptive names.
4. Prefer fewer arguments.
5. Have no side effects.
6. Don't use flag arguments.
   Split method into several independent methods that can be called from the client without the flag.

### Comments rules
1. Always try to explain yourself in code.
2. Don't be redundant.
3. Don't add obvious noise.
4. Don't use closing brace comments.
5. Don't comment out code.
   Just remove.
6. Use as explanation of intent.
7. Use as clarification of code.
8. Use as warning of consequences.

### Source code structure
1. Separate concepts vertically.
2. Related code should appear vertically dense.
3. Declare variables close to their usage.
4. Dependent functions should be close.
5. Similar functions should be close.
6. Place functions in the downward direction.
7. Keep lines short.
8. Don't use horizontal alignment.
9. Use white space to associate related things and disassociate weakly related.
10. Don't break indentation.

### Objects and data structures
1. Hide internal structure.
2. Prefer data structures.
3. Avoid hybrids structures (half object and half data).
4. Should be small.
5. Do one thing.
6. Small number of instance variables.
7. Base class should know nothing about their derivatives.
8. Better to have many functions than to pass some code into a function to select a behavior.
9. Prefer non-static methods to static methods.

### Tests
1. One assert per test.
2. Readable.
3. Fast.
4. Independent.
5. Repeatable.

### Code smells
1. Rigidity.
   The software is difficult to change.
   A small change causes a cascade of subsequent changes.
2. Fragility.
   The software breaks in many places due to a single change.
3. Immobility.
   You cannot reuse parts of the code in other projects because of involved risks and high effort.
4. Needless Complexity.
5. Needless Repetition.
6. Opacity.
   The code is hard to understand.

## User Input Encoding

Never interpolate user-supplied data directly into JavaScript string literals inside HTML attributes (e.g. `onclick="fn('${name}')"`).
Apostrophes, quotes, and other characters in values like device names will silently break the JS string and cause the handler to never fire.
Instead, use `data-*` attributes for the values and pass `this` to the handler, which reads `this.dataset.foo` — this is immune to any characters in the value.
The same principle applies everywhere user data touches a string delimiter: SQL queries (use parameterized queries), shell commands (use argument arrays not string interpolation), URL parameters (use `encodeURIComponent`), and HTML content (use `textContent` or a proper escape function, never `innerHTML` with raw user data).

## Markdown Files

Before writing or significantly editing a markdown file, ask whether it will be long-lived in source control (e.g. CLAUDE.md, README, docs) or short-lived (e.g. a PR review draft, a one-off note).
For long-lived files, format with one sentence per line so each sentence is its own diff line — this keeps git history readable and prevents unrelated sentence changes from appearing in the same hunk.
For list items with multiple sentences, indent continuation sentences by 3 spaces so they stay visually grouped with their list entry.

## Code Review

Keep the Coding guidelines above in mind.
Also, unless prompted to automatically publish comments on a github PR, always put comment drafts in a local markdown file **in the current working directory** (not /tmp/ — the file must be visible in the IDE file tree).
The draft should have all the information needed to publish comments later without refetching.
Write each finding's body in the draft exactly as it will be posted, preface included — do not add the preface only at posting time.
Preface every comment body (each individual finding and any overall/summary body) with the literal string `Ryan's Claude 🤖:` immediately followed by the writeup, so the draft file is a verbatim, ready-to-post copy of what goes to GitHub.
Start each finding's body with its severity tag in bold immediately after the preface — e.g. `Ryan's Claude 🤖: **[BUG]** ...` or `Ryan's Claude 🤖: **[NIT]** ...` — so the tag is prominent in the posted comment, not just in the draft's heading.
Note that you should always post from the file not from memory as it may have been reviewed by Ryan.
Post the comment body exactly as written — do not strip or summarize any part of it, including any notes Ryan has added before `Ryan's Claude 🤖:`.

**Reading PR comments:** Always use `~/.claude/scripts/gh-pr-comments.sh <PR_NUMBER>` to read PR review threads and issue-level comments.
Never use raw `gh api` calls for this — the script formats threads readably and handles pagination.
This applies to reading, searching, or checking for comments by any user.

**Reconstructing "what happened and when" on a PR** (e.g. did an agent revisit the PR after opening it, did a bot comment land before or after a given commit): use `~/.claude/scripts/gh-pr-activity-timeline.sh <PR_NUMBER> [owner/repo]`.
It merges commits, comments (including bot comments), reviews, edits, and force-pushes from the PR's issue-timeline API into one chronological table, so there's no need to separately fetch commits and comments and manually interleave them by timestamp.

**Always post on a line of code:** When a finding references a specific file+line, always use `~/.claude/scripts/gh-pr-inline-comment.sh` — never use `gh-pr-reply.sh --issue` for line-specific findings.
The script tries a resolvable PR review comment first; if the line is not in the diff it automatically falls back to a commit comment, which is still inline at the correct line.
Only use `gh-pr-reply.sh --issue` for findings that genuinely have no associated file or line.

**Resolving exact line numbers at draft time (no refetch on post):** Before writing each finding to the draft, resolve its exact line number using `~/.claude/scripts/gh-pr-file.sh <PR_NUMBER> <FILE_PATH> | grep -n "PATTERN"`.
Store the resolved line number, file path, and PR number directly in the finding's heading in the draft — e.g., `### 1. [BUG] Title — src/foo.tsx:161 (PR 725)` — so posting with `~/.claude/scripts/gh-pr-inline-comment.sh` needs no further lookups.
Never use approximate line numbers in drafts — always grep to confirm the exact line before writing.
This applies to local code reviews too: resolve all line numbers before writing the draft, not at posting time.

**Reading files during PR analysis:** When reviewing or verifying findings against a PR's code, always use `~/.claude/scripts/gh-pr-file.sh <PR_NUMBER> <FILE_PATH>` to read the post-PR version of files.
Never read files directly from disk with Read/cat during PR review — the working tree may not be in the same state.

**Focus findings on the diff:** Only report issues introduced or meaningfully exposed by the PR's changes.
Pre-existing issues in unchanged lines are out of scope unless the PR's changes make them newly reachable or worse.
If a pre-existing issue is worth noting anyway, mark it clearly as `[PRE-EXISTING]` and place it in a separate section so it doesn't inflate the PR's bug count.

## Addressing PR Comments

When asked to address PR comments, first ask whether to take **local actions only** or **full PR updates**.

- **Local only** — update code and prepare comment replies in a local draft file, but do not commit (there may be more comments to address first).
- **Full PR update** — make code changes, then commit, push, and post replies on the PR.

## Git

Before committing, check the current branch.
If it looks like a tracking branch (`main`, `master`, `develop`, or similar), create a feature branch first — e.g. `ryan/brief-description-of-change` — and commit there instead.
Do not commit directly to tracking branches.

Before drafting a commit message for a shared repository (e.g. one of the last 5 commits is not by hryanjones), ask: "Are there any links to context I should include — e.g. a ticket, QA item, GitHub issue, or design doc?"
Wait for the answer before committing.
If the user provides a link, it must appear in the commit message body.
If the conversation already contains a link to a ticket or task that motivated the change, include it without asking.
Always use the full URL in commit messages — never just an ID (e.g. use `https://...` not a bare ID like `cmqgujecj000dmc071m0aqnrh`).

Never run `git push` unless explicitly asked to push in that specific message.
Treat each commit request independently — a prior "commit and push" does not carry forward to the next task.
If asked to "commit" a change in a previous message, please ask for user to clarify before working whether you should commit the change.

## Troubleshooting browser issues, especially with visibility and styling

If a code investigation of styling in a browser isn't yielding answers, you may ask me to run a single command in the browser console.
The command should be a single command wrapped in `copy()` and gathering all the inputs that you would need to troubleshoot.
