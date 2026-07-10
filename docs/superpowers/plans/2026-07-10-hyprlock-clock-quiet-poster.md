# Hyprlock Quiet Poster Clock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current two-tone JetBrains Mono lock clock with the approved Quiet Poster design: Inter Display time, short accent rule, and `FRI / JUL 10` date.

**Architecture:** `lock-clock.sh` remains the only producer of Pango markup for time and date labels. `hyprlock.conf` owns visual placement, font choices, shadows, and the new rule `shape`. Color generation stays unchanged because the existing `$lock_time`, `$lock_accent`, `$lock_ampm`, and `$lock_date` tokens already cover the design.

**Tech Stack:** hyprlock config, Bash, Pango markup, matugen-generated color tokens, Nix commands for validation.

## Global Constraints

- Keep background image, left-bottom scrim, shadows, input field, and animations unchanged except where label coordinates require small adjustment.
- Do not change `home-manager/desktop/hyprland/lock-colors.template.conf`.
- Do not introduce new fixed colors.
- Do not use `$lock_accent` for the clock colon or minute digits.
- Use Inter Display Medium for the time label, with Inter Medium as the only fallback if hyprlock cannot resolve Inter Display on the target machine.
- Use JetBrainsMono Nerd Font Medium for the date label.
- Date format must be `FRI / JUL 10`.
- Acceptance commands are `nix run .#build` and `nix run .#fmt -- --fail-on-change`.

---

## File Structure

- Modify `home-manager/desktop/hyprland/scripts/lock/lock-clock.sh`: Generate single-color time markup and slash-separated date markup.
- Modify `home-manager/desktop/hyprland/hyprlock.conf`: Change clock typography and coordinates, add the short accent rule as a `shape`, and keep the input field unchanged.
- Do not modify `home-manager/desktop/hyprland/lock-colors.template.conf`: Existing color tokens are sufficient.
- No new test file is needed. This repo does not currently have shell unit tests for lock scripts; each task includes command-level checks using `LOCK_CLOCK_AT`.

### Task 1: Update Clock Markup

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/lock/lock-clock.sh`

**Interfaces:**

- Consumes: `time "$lock_time" "$lock_accent" "$lock_ampm"` from `hyprlock.conf`
- Consumes: `date "$lock_accent" "$lock_date"` from `hyprlock.conf`
- Produces: `time` output where hour, colon, and minute all use argument 2, and AM/PM uses argument 4
- Produces: `date` output where weekday uses argument 2 and ` / MON DD` uses argument 3

- [ ] **Step 1: Capture current failing behavior**

Run:

```bash
LOCK_CLOCK_AT='2026-07-10 17:02:00' \
  home-manager/desktop/hyprland/scripts/lock/lock-clock.sh \
  time 'rgba(efe0d6ff)' 'rgba(ffb77cff)' 'rgba(d6c3b6ff)'
```

Expected before implementation: output contains two color spans for the time digits, with `:02` inside the `#ffb77c` span.

Run:

```bash
LOCK_CLOCK_AT='2026-07-10 17:02:00' \
  home-manager/desktop/hyprland/scripts/lock/lock-clock.sh \
  date 'rgba(ffb77cff)' 'rgba(efe0d6e6)'
```

Expected before implementation: output contains `FRI` and ` · JUL 10`.

- [ ] **Step 2: Replace the `time` and `date` case bodies**

In `home-manager/desktop/hyprland/scripts/lock/lock-clock.sh`, replace only the `time)` and `date)` branches with:

```bash
time)
  printf '%s%s</span>' "$(span_open "$2" "")" "$(esc "$(d +%I):$(d +%M)")"
  printf '%s %s</span>\n' "$(span_open "$4" "size='28672' rise='45000'")" \
    "$(esc "$(d +%p)")"
  ;;
date)
  printf '%s%s</span>' "$(span_open "$2" "")" \
    "$(esc "$(d +%a | tr '[:lower:]' '[:upper:]')")"
  printf '%s%s</span>\n' "$(span_open "$3" "")" \
    "$(esc " / $(d '+%b %d' | tr '[:lower:]' '[:upper:]')")"
  ;;
```

- [ ] **Step 3: Verify time markup uses one color for all digits**

Run:

```bash
LOCK_CLOCK_AT='2026-07-10 17:02:00' \
  home-manager/desktop/hyprland/scripts/lock/lock-clock.sh \
  time 'rgba(efe0d6ff)' 'rgba(ffb77cff)' 'rgba(d6c3b6ff)'
```

Expected after implementation:

```html
<span foreground="#efe0d6">05:02</span
><span foreground="#d6c3b6" size="28672" rise="45000"> PM</span>
```

- [ ] **Step 4: Verify date markup uses slash separator**

Run:

```bash
LOCK_CLOCK_AT='2026-07-10 17:02:00' \
  home-manager/desktop/hyprland/scripts/lock/lock-clock.sh \
  date 'rgba(ffb77cff)' 'rgba(efe0d6e6)'
```

Expected after implementation:

```html
<span foreground="#ffb77c">FRI</span
><span foreground="#efe0d6" fgalpha="90%"> / JUL 10</span>
```

- [ ] **Step 5: Commit Task 1**

```bash
git add home-manager/desktop/hyprland/scripts/lock/lock-clock.sh
git commit -m "style(hyprlock): simplify quiet poster clock markup"
```

### Task 2: Update Hyprlock Layout

**Files:**

- Modify: `home-manager/desktop/hyprland/hyprlock.conf`

**Interfaces:**

- Consumes: Task 1 `time` output with single-color `05:02` and low-contrast `PM`
- Consumes: Task 1 `date` output with accent weekday and slash-separated date
- Produces: hyprlock label and shape layout for the Quiet Poster design

- [ ] **Step 1: Capture current layout config**

Run:

```bash
sed -n '30,66p' home-manager/desktop/hyprland/hyprlock.conf
```

Expected before implementation: time label uses `font_size = 150`, `font_family = JetBrainsMono Nerd Font SemiBold`, and there is no `shape` between the time and date labels.

- [ ] **Step 2: Replace the time label and insert the rule shape**

In `home-manager/desktop/hyprland/hyprlock.conf`, replace the first clock `label` block and insert this `shape` immediately after it:

```ini
label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh time "$lock_time" "$lock_accent" "$lock_ampm"
    font_size = 135
    font_family = Inter Display Medium
    position = 72, 140
    halign = left
    valign = bottom
    shadow_passes = 3
    shadow_size = 7
    shadow_color = $lock_shadow
    shadow_boost = 1.15
}

shape {
    monitor =
    size = 90, 4
    color = $lock_accent
    rounding = 2
    border_size = 0
    position = 76, 118
    halign = left
    valign = bottom
}
```

- [ ] **Step 3: Replace the date label block**

In `home-manager/desktop/hyprland/hyprlock.conf`, replace the second clock `label` block with:

```ini
label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh date "$lock_accent" "$lock_date"
    font_size = 26
    font_family = JetBrainsMono Nerd Font Medium
    position = 76, 80
    halign = left
    valign = bottom
    shadow_passes = 2
    shadow_size = 4
    shadow_color = $lock_shadow
    shadow_boost = 1.1
}
```

- [ ] **Step 4: Verify config contains exactly one rule shape**

Run:

```bash
rg -n 'shape \\{|font_family = Inter Display Medium|font_size = 135|lock-clock.sh time|lock-clock.sh date' \
  home-manager/desktop/hyprland/hyprlock.conf
```

Expected after implementation:

```text
35:    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh time "$lock_time" "$lock_accent" "$lock_ampm"
36:    font_size = 135
37:    font_family = Inter Display Medium
49:shape {
64:    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh date "$lock_accent" "$lock_date"
```

Line numbers may differ by a few lines, but the output must include one `shape {` block between the time and date labels and must include `font_family = Inter Display Medium`.

- [ ] **Step 5: Commit Task 2**

```bash
git add home-manager/desktop/hyprland/hyprlock.conf
git commit -m "style(hyprlock): apply quiet poster clock layout"
```

### Task 3: Verify And Tune

**Files:**

- Modify if needed: `home-manager/desktop/hyprland/hyprlock.conf`
- Do not modify: `home-manager/desktop/hyprland/lock-colors.template.conf`

**Interfaces:**

- Consumes: Task 1 script output
- Consumes: Task 2 hyprlock layout
- Produces: final tuned coordinates and validation evidence

- [ ] **Step 1: Confirm color template remains unchanged**

Run:

```bash
git diff -- home-manager/desktop/hyprland/lock-colors.template.conf
```

Expected: no output.

- [ ] **Step 2: Check the longest planned date format**

Run:

```bash
LOCK_CLOCK_AT='2026-09-23 17:02:00' \
  home-manager/desktop/hyprland/scripts/lock/lock-clock.sh \
  date 'rgba(ffb77cff)' 'rgba(efe0d6e6)'
```

Expected:

```html
<span foreground="#ffb77c">WED</span
><span foreground="#efe0d6" fgalpha="90%"> / SEP 23</span>
```

- [ ] **Step 3: Run formatting validation**

Run:

```bash
nix run .#fmt -- --fail-on-change
```

Expected: command exits 0 and reports no formatting changes.

- [ ] **Step 4: Run build validation**

Run:

```bash
nix run .#build
```

Expected: command exits 0.

- [ ] **Step 5: Capture a lock preview if running inside Hyprland**

Run:

```bash
home-manager/desktop/hyprland/scripts/lock/lock-preview.sh /tmp/hyprlock-quiet-poster.png
```

Expected: `/tmp/hyprlock-quiet-poster.png` is created and shows the left-bottom stack as `05:02 PM`, short orange rule, and `FRI / JUL 10`.

If this command fails because the session is not running under Hyprland or lacks screenshot permissions, record the failure in the task notes and rely on the script, fmt, and build checks until an interactive Hyprland session is available.

- [ ] **Step 6: Tune only if the preview shows interference**

If the clock is too close to the character or input field, adjust only these values in `home-manager/desktop/hyprland/hyprlock.conf`:

```ini
    font_size = 130
    position = 72, 135
```

For the rule, keep width and height fixed and move only the y coordinate:

```ini
    position = 76, 113
```

For the date, keep font family fixed and move only the y coordinate:

```ini
    position = 76, 75
```

After any tuning, rerun:

```bash
nix run .#fmt -- --fail-on-change
nix run .#build
```

Expected: both commands exit 0.

- [ ] **Step 7: Commit Task 3**

If no tuning was needed:

```bash
git status --short
```

Expected: no tracked changes from this task.

If tuning was needed:

```bash
git add home-manager/desktop/hyprland/hyprlock.conf
git commit -m "style(hyprlock): tune quiet poster clock spacing"
```
