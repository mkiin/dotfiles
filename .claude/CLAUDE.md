# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Dotfiles Workflow (chezmoi)

**This repo is managed by chezmoi. Edit the chezmoi source only, then sync — do NOT dual-edit.**

Files under `home/dot_config/...` are the chezmoi source. chezmoi materializes them into `~/.config/...` on `apply`. Naming translation rules:

- `dot_foo` → `.foo` (hidden file/dir)
- `executable_foo.sh` → `foo.sh` with mode 0755
- Other names pass through as-is

### Required flow

1. Edit the source only: `dotfiles/home/dot_config/<path>`
2. `chezmoi diff` — preview what will change in the live tree (expected: non-empty diff reflecting your edit)
3. `chezmoi apply` — sync live files from source
4. `chezmoi diff` — re-run to confirm zero diff (source and live are now identical)

### Forbidden

- ❌ Editing `~/.config/<path>` and `dotfiles/home/dot_config/<path>` separately in the same change. This creates drift and muddies the source-of-truth.
- ❌ Skipping `chezmoi diff` before `apply`. Always preview first so surprises are caught before the live tree mutates.

### Exception

Live-only experiments (testing a value before committing to source) are fine, but must be either reverted or propagated to source before the task is considered done. No half-applied state should outlive the session.

## 6. Comments — Earn the Right

**Default: no comments. When tempted, prove load-bearing before writing.**

This section is about *what to do when you decide a comment is needed*. The decision itself defaults to "no".

### Deletion test (applied to every comment candidate)

Before writing, answer in one sentence: **"If this comment is removed, who gets stuck on what?"**

If the answer is vague ("future readers might want it", "good to document", "for clarity"), don't write it. Only write when you can name a concrete confusion the comment prevents.

### Process — verbalize before typing

For each comment you're tempted to write:

1. Draft the load-bearing fact in **one sentence**.
2. If compressing it to one sentence is hard, the comment will bloat. Instead:
   - Keep only the single most load-bearing fact, drop the rest.
   - Express intent through naming or structure — not prose.

### Anti-pattern types — do not write comments that are…

- **External mechanism tutorials** — kernel / library / protocol internals not this code's job
- **Rejected-alternative comparisons** — "X より Y", "we tried A but B is better"
- **Caller-side context** — who calls this, under what flow (caller's concern, not this code's)
- **Result boasting** — smooth / fast / no flicker (effect, not contract)
- **Restating what the code already says** — narrating the obvious
- **"注意:" / "Note:" multi-sentence prose** — paragraph-shaped commentary

If your draft fits one of these types, the answer is "no comment", not "shorter version of the same".

### Why no Before/After example here

Concrete examples cause overfitting on surface features (specific words, kanji density, line shape). The test + process + type list above are the harness; the calibration is your job per-comment, not pattern-matching against a canonical example.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
