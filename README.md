# codex-fixed-retry

An opinionated patch set for OpenAI Codex CLI that changes dropped-stream retries from exponential backoff to a fixed 1 second cadence by default.

It is split into two patches:

1. `0001-add-configurable-stream-retry-settings.patch`
   Adds `stream_retry_delay_ms` and `stream_retry_backoff` to provider config so retry behavior becomes user-configurable in TOML.
2. `0002-default-stream-retries-to-fixed-1s.patch`
   Keeps that configurability, but changes the local default to:
   - `stream_retry_delay_ms = 1000`
   - `stream_retry_backoff = "fixed"`

This repo exists for the exact case discussed in upstream issue `#16164`:
https://github.com/openai/codex/issues/16164

## What Changes

After these patches are applied, Codex still supports per-provider overrides in `~/.codex/config.toml`, but the built-in default behavior becomes:

```toml
stream_max_retries = 5
stream_retry_delay_ms = 1000
stream_retry_backoff = "fixed"
```

That means disconnected streams retry once per second instead of exploding into multi-minute waits.

## Local Override

If you still want to override the retry behavior explicitly for a provider, you can do it in TOML:

```toml
[model_providers.openai]
stream_max_retries = 100
stream_retry_delay_ms = 1000
stream_retry_backoff = "fixed"
```

Use your own provider id instead of `openai` if you are routing through a custom upstream.

## Repo Layout

- `patches/`
  Standard `git am` patches applied in order.
- `scripts/apply-patches.sh`
  Applies the patch set to an upstream Codex checkout on macOS/Linux.
- `scripts/apply-patches.ps1`
  Applies the patch set to an upstream Codex checkout on Windows.
- `scripts/install.sh`
  Downloads the latest patched macOS release asset from this repo and installs a user-local `codex` shim.
- `scripts/install.ps1`
  Downloads the latest patched Windows release asset from this repo and installs user-local `codex.cmd` / `codex.ps1` shims.
- `.github/workflows/release.yml`
  GitHub Actions workflow that clones upstream `openai/codex`, applies both patches, builds release binaries, and publishes GitHub release assets.

## Install Patched Codex

The installers do not overwrite your globally installed npm/Homebrew Codex. They install the patched binary under your home directory and create a `codex` shim in `~/.local/bin`.

That design is deliberate:

- it avoids touching system install locations
- it survives upstream npm upgrades
- it lets you keep the patched binary earlier in `PATH`

### macOS

```bash
bash ./scripts/install.sh
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

Make sure `~/.local/bin` is before your npm/Homebrew/global bin directory in `PATH`, otherwise the original `codex` command will still win.

## Build A New Patched Release

Use the GitHub Actions workflow manually:

1. Open `Actions`
2. Run `build-release`
3. Set `upstream_ref` to the upstream tag/branch/commit you want to patch
4. Optionally set `release_tag`

The workflow will:

1. clone `https://github.com/openai/codex`
2. checkout the requested ref
3. apply both patches
4. build macOS and Windows binaries
5. publish GitHub release assets from this repo

## Apply Patches To A Local Upstream Checkout

### macOS / Linux

```bash
./scripts/apply-patches.sh /path/to/codex
```

### Windows

```powershell
.\scripts\apply-patches.ps1 -UpstreamRepo C:\path\to\codex
```

Both scripts use `git am`, so they preserve patch metadata and fail cleanly if upstream drift breaks the patch.
