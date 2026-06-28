# Claude Code Guidelines

## Clipboard

When you want the user to copy a command, text, or code snippet, pipe it to `gocopy` via Bash instead of just displaying it.

```bash
echo "something to copy" | gocopy
```
This places the content into the user's clipboard.

## Shell Tooling Rules

- Use `rg` (ripgrep) instead of `grep`. Never run `grep` or `grep -r`.
- Use `fd` instead of `find`. Never run `find` for file search.
- **By default, ignore `.gitignore`/`.ignore` rules so excluded files/dirs are not silently dropped.** Pass `--no-ignore --hidden` (rg) / `--no-ignore --hidden` (fd). Shorthand: `rg -uu` and `fd -HI`.
  - Only omit these flags when the user explicitly wants gitignore-aware results (e.g. "only tracked files").
- Examples:
  - Search file contents: `rg -uu "pattern" path/`
  - Find files by name: `fd -HI "pattern" path/`
  - Find files by extension: `fd -HI -e ts`
- If `rg` or `fd` is unavailable in the environment, stop and tell me before falling back.
