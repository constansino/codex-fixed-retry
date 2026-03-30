#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/openai-codex-checkout" >&2
  exit 1
fi

repo_dir="$(cd "$1" && pwd)"
patch_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../patches" && pwd)"

if [[ ! -d "$repo_dir/.git" ]]; then
  echo "Not a git repository: $repo_dir" >&2
  exit 1
fi

git -C "$repo_dir" am \
  "$patch_dir/0001-add-configurable-stream-retry-settings.patch" \
  "$patch_dir/0002-default-stream-retries-to-fixed-1s.patch"

echo "Applied fixed-retry patch set to $repo_dir"
