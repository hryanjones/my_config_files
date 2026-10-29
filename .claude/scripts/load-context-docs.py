"""SessionStart hook: refresh local Markdown copies of Ryan's two context docs.

~/.claude/CLAUDE.md imports the copies with @, which loads them in full; hook output itself is
cut to a short preview when long, so the hook prints only a one-line status.

Run with the jogra-butler venv: ~/.butler/venv/bin/python3 -I ~/.claude/scripts/load-context-docs.py
Uses the butler's read-only Drive token and never opens a browser login.
If Google can't be reached, the previous copy is kept and marked STALE at the top.
"""

import socket
import sys
from datetime import datetime
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

CACHE_DIR = Path.home() / ".cache" / "claude-context-docs"
MEMORY_ROOT = Path.home() / ".claude" / "projects"
DOCS = [
    ("butlers-book.md", "Butler's Book (household and family; shared with Malvika)",
     "1Dr8goQ-T8AA0BetnQk8LSbaFbwH2lKeE48KjEDc7iZQ"),
    ("ryans-claude-notes.md", "Ryan's Claude Notes (Ryan-only)",
     "11ZBOOdh5eWjfnPtQfrPzwbmd-QJroHqR8y8xWa3O7WY"),
    ("ryans-claude-code-notes.md", "Ryan's Claude Code Notes (Ryan-only; Claude Code only)",
     "1VLAnfF8jdjAUq-LaWfzr3o8C2BPKocq0S9ZvxkC6pIA"),
]
TOKEN_PATH = Path.home() / ".butler" / "tokens" / "drive_token.json"
SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]
NETWORK_TIMEOUT_SECONDS = 10
STALE_MARKER = "(STALE:"


def doc_url(doc_id: str) -> str:
    return f"https://docs.google.com/document/d/{doc_id}/edit"


def drive_service():
    creds = Credentials.from_authorized_user_file(str(TOKEN_PATH), SCOPES)
    if not creds.valid:
        creds.refresh(Request())
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def export_markdown(drive, doc_id: str) -> str:
    return drive.files().export(fileId=doc_id, mimeType="text/markdown").execute().decode("utf-8")


def fresh_copy(title: str, doc_id: str, markdown: str) -> str:
    fetched_at = datetime.now().strftime("%Y-%m-%d %H:%M")
    return f"<!-- {title}: {doc_url(doc_id)} (fetched {fetched_at}) -->\n\n{markdown}"


def mark_stale(cache_path: Path, doc_id: str, reason: str) -> None:
    """Keep the previous copy, adding one STALE line at the top (once)."""
    if not cache_path.exists():
        cache_path.write_text(
            f"{STALE_MARKER} no copy yet; fetch failed: {reason}. Tell Ryan and read {doc_url(doc_id)})\n"
        )
        return
    previous = cache_path.read_text()
    if previous.startswith(STALE_MARKER):
        previous = previous.split("\n", 1)[1]
    cache_path.write_text(f"{STALE_MARKER} live fetch failed: {reason}. Tell Ryan.)\n{previous}")


def cached_markdown(cache_path: Path) -> str:
    """The doc text in a cached copy, without the STALE line and fetched-at header."""
    if not cache_path.exists():
        return ""
    lines = cache_path.read_text().split("\n")
    if lines[0].startswith(STALE_MARKER):
        lines = lines[1:]
    header_and_blank_line = 2
    return "\n".join(lines[header_and_blank_line:])


def refresh(drive, filename: str, title: str, doc_id: str) -> str:
    """Refresh one cached doc; return its status: unchanged, changed or STALE."""
    cache_path = CACHE_DIR / filename
    try:
        markdown = export_markdown(drive, doc_id)
    except Exception as error:  # any failure keeps the previous copy
        mark_stale(cache_path, doc_id, type(error).__name__)
        return "STALE"
    previous = cached_markdown(cache_path)
    cache_path.write_text(fresh_copy(title, doc_id, markdown))
    if previous == markdown:
        return "unchanged"
    return "changed"


def main() -> None:
    socket.setdefaulttimeout(NETWORK_TIMEOUT_SECONDS)
    CACHE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        drive = drive_service()
    except Exception as error:
        print(f"load-context-docs: Google auth failed: {error}", file=sys.stderr)
        for filename, _, doc_id in DOCS:
            mark_stale(CACHE_DIR / filename, doc_id, "Google auth failed")
        print("Context docs: STALE (Google auth failed); tell Ryan.")
        report_pending_memories()
        return

    statuses = {filename: refresh(drive, filename, title, doc_id) for filename, title, doc_id in DOCS}
    print("Context docs: " + ", ".join(f"{name} {status}" for name, status in statuses.items()))
    changed = [name for name, status in statuses.items() if status == "changed"]
    if changed:
        paths = ", ".join(str(CACHE_DIR / name) for name in changed)
        print(f"The copy imported via CLAUDE.md predates this refresh; read {paths} before relying on it.")
    report_pending_memories()


def report_pending_memories() -> None:
    """List local memory files not yet moved into the docs (MEMORY.md indexes don't count)."""
    pending = sorted(path for path in MEMORY_ROOT.glob("*/memory/*.md") if path.name != "MEMORY.md")
    if pending:
        print("Memory files waiting to be moved into the docs (see CLAUDE.md):")
        print("\n".join(f"- {path}" for path in pending))


if __name__ == "__main__":
    main()
