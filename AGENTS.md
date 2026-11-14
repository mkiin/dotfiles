# Repository Instructions

## Scope and packages

- Before proposing a NixOS or Home Manager package, check whether it exists in the nixpkgs revision pinned by this repository's `flake.lock`. If it has no standalone attribute, also check collection packages and how to select their components.
- If a candidate is unavailable in the pinned nixpkgs, stop that package's installation work. Do not fetch external sources or add a custom derivation without approval. Present alternatives from nixpkgs, explain their differences, and wait for the user's decision.
- Limit changes to the requested task. Do not change unrelated settings or add unrelated work.
- Do not create or edit `README.md`. It is not a work log.

## Lua diagnostics workflow

- Use LuaLS itself to check Lua changes, rather than asking the user to transcribe editor diagnostics or provide screenshots.
- Run the following command from the repository root against saved files:

  ```sh
  lua-language-server --check=. --checklevel=Warning --check_format=pretty
  ```

- Read the reported file paths, positions, and diagnostics; fix the source; then rerun the command. Repeat until errors and warnings within the task's scope are resolved.
- Exit code `0` means the check passed; a nonzero exit code means it did not. Explicitly report any remaining unrelated diagnostics instead of claiming a clean check.
- Do not disable diagnostics, lower their severity, add blanket suppressions, or replace useful types with `any` merely to make the check pass.
- Use the shared root `.luarc.json` and the same type definitions used by the editors. If the Nix-managed `~/.local/share/nvim/lua-library` is missing or stale, address that environment issue before treating missing types as source bugs.
- Keep formatting separate from diagnostics. For Lua formatting checks, use the existing treefmt configuration:

  ```sh
  nix fmt -- --fail-on-change --formatters stylua
  ```

## Privileged commands

- When an authorized task needs administrator privileges, execute the required command yourself through `pkexec` so that the graphical polkit authentication dialog appears. The user will enter their password in that dialog.
- Do not ask the user to copy and run a command containing `sudo`, and do not request their password in chat or through tool input.
- Use an absolute executable path with `pkexec`. Keep builds and other unprivileged work under the normal user; elevate only the operation that requires it.
- The existing `switch` app invokes `sudo` internally. Account for that when executing an authorized switch so authentication uses the graphical dialog rather than handing the command back to the user.
- If graphical authentication is unavailable or canceled, report the blocker. Do not silently fall back to a terminal password prompt.
- This authentication preference does not authorize unrelated system changes or destructive operations.

## Flake app commands

Run commands from the repository root. Use the existing flake apps for build and deployment workflows, following the graphical authentication policy above when privileges are needed.

```sh
# Build only.
nix run .#build -- oregairu-yukino

# Apply the production configuration after a successful build.
# This app invokes sudo internally; use graphical authentication when executing it.
nix run .#switch -- oregairu-yukino

# Install minimal NixOS from the ISO. This erases the target SSD.
# Execute only when the user has explicitly authorized the installation and target disk.
pkexec "$(command -v nix)" --extra-experimental-features 'nix-command flakes' run .#install -- \
  oregairu-yukino /dev/disk/by-id/<SSD-ID>
```

The `build` and `switch` apps default to the current hostname when none is specified.
See `INSTALL.md` for installation instructions and disko dry runs.

## Communication

- Take responsibility for mistakes directly. Avoid defensive excuses or shifting responsibility onto missing verification or external circumstances.
- Explain how to correct a problem and identify the next concrete step. Keep the conversation moving toward a solution instead of stopping at a description of what went wrong.
