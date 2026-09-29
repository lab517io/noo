# Noo Export to Obsidian Format

## Overview

Noo can export its database to a directory structure compatible with [Obsidian](https://obsidian.md/) vaults. The export converts the hierarchical task tree into directories with Markdown files, and time tracking data into plain text timeline files.

## Access

**File > Export to Obsidian...** — select an empty or existing directory as the export target.

## Directory Structure

The task tree hierarchy maps directly to the filesystem:

- **Task with children** becomes a **directory** named after the task.
  - Its own content is saved as `<Task Title>.md` inside that directory.
  - Its time records are saved as `timeline.txt` inside that directory.
  - Child tasks appear as files or subdirectories within.

- **Leaf task** (no children) becomes a **Markdown file** `<Task Title>.md` in its parent directory.
  - Its time records are saved as `<Task Title> - timeline.txt` alongside the `.md` file.

### Example

Given this task tree in Noo:

```
Work
├── Project Alpha
│   ├── Design
│   └── Implementation
└── Project Beta
Notes
```

The export produces:

```
export-dir/
├── Work/
│   ├── Work.md
│   ├── timeline.txt
│   ├── Project Alpha/
│   │   ├── Project Alpha.md
│   │   ├── timeline.txt
│   │   ├── Design.md
│   │   ├── Design - timeline.txt
│   │   ├── Implementation.md
│   │   └── Implementation - timeline.txt
│   ├── Project Beta.md
│   └── Project Beta - timeline.txt
├── Notes.md
└── Notes - timeline.txt
```

## Markdown Files

Each `.md` file starts with a level-1 heading matching the task title, followed by the task content converted to Markdown.

```markdown
# Task Title

Task content here...
```

Content is stored as a Quill Delta, and the conversion walks it a line at a time: a line's block format is written as its Markdown prefix, and inline runs as their Markdown marks.

| Quill | Markdown |
|-------|----------|
| Header 1–6 | `# ` … `###### ` |
| Bullet list | `- ` |
| Ordered list | `1. ` |
| Checklist | `- [x] ` / `- [ ] ` |
| Indent level *n* | four spaces per level, before the list marker |
| Block quote | `> ` |
| Code block | fenced with ```` ``` ```` |
| Bold / italic / strike / code | `**` / `*` / `~~` / `` ` `` |
| Link | `[text](url)` |

Each Quill line is one Markdown line; a paragraph break is a line break in the file. Underline, colour, font and size have no Markdown form and are dropped. Rows written before the Quill migration still hold HTML and are converted from that instead.

The importer reads the same forms back (headings, lists, quotes, fences, the inline marks and links). It skips `_images/` at the vault root and any hidden (dot) directory, so an exported vault re-imports without gaining an `_images` task. A `Foo.md` beside a `Foo/` folder — Obsidian's folder-note layout, which the exporter never produces — is taken as the folder task's own note when the folder has no `Foo/Foo.md`, and imported as a leaf task when it has.

## Images

Images embedded in task content are stored as attachments, so the export writes the bytes out and links to them:

- Every embedded image is copied into a single `_images/` folder at the export root.
- An image used by several notes is written **once** and linked from each of them.
- The link is relative to the note: `![](../_images/screenshot.png)` from a note one level down.
- File names come from the attachment name, with ` (2)`, ` (3)`, … inserted before the extension on collision. Path characters are sanitized as for task titles.
- Remote images (`http`/`https`) keep their URL and are not downloaded.
- An image whose attachment has been deleted is skipped, leaving no broken link.

```
export-dir/
├── _images/
│   └── screenshot.png
├── Work/
│   └── Work.md          ← ![](../_images/screenshot.png)
└── Notes.md             ← ![](_images/screenshot.png)
```

## Timeline Files

Timeline files are plain text with a header showing the task name and total tracked time, followed by one line per time record.

```
# Time records for: Task Title
# Total time: 12:45:30

2026-01-10 09:00:00  ->  2026-01-10 12:30:00  (03:30:00)
2026-01-11 14:00:00  ->  2026-01-11 17:15:30  (03:15:30)
2026-01-12 10:00:00  ->  2026-01-12 16:00:00  (06:00:00)
```

Each line contains:

| Field | Format | Description |
|-------|--------|-------------|
| Start | `yyyy-MM-dd HH:mm:ss` | Local time when work started |
| End | `yyyy-MM-dd HH:mm:ss` | Local time when work ended |
| Duration | `HH:MM:SS` | Length of the interval |

Timeline files are only created when a task has at least one time record. Tasks with no tracked time produce no timeline file.

## Filename Sanitization

Task titles are sanitized for filesystem compatibility:

- Characters `/ \ : * ? " < > |` are replaced with `_`
- Trailing dots and spaces are stripped
- Length is capped at 200 characters
- Tasks with empty titles are named `untitled_<id>`
- A name Windows reserves for a device (`CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`, with or without an extension) gets `_` appended to its stem, on every platform, so the vault survives being copied to Windows. Image names get the same treatment.
- A top-level task titled `_images` is written as `_images (2)`, since that folder holds the images.
