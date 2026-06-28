# Codex Global Instructions

## Clipboard

When you want the user to copy a command, text, or code snippet, pipe it to `gocopy` instead of just displaying it.

```bash
echo "something to copy" | gocopy
```

## Shell Tooling Rules

- Use `rg` (ripgrep) instead of `grep`. Never run `grep` or `grep -r`.
- Use `fd` instead of `find`. Never run `find` for file search.
- By default, ignore `.gitignore`/`.ignore` rules: pass `--no-ignore --hidden` (`rg -uu` / `fd -HI`).
  - Only omit these flags when only tracked files are wanted.
- If `rg` or `fd` is unavailable, stop and tell the user before falling back.
