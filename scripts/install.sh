#!/usr/bin/env bash
set -euo pipefail

repo="${CODEX_FIXED_RETRY_REPO:-constansino/codex-fixed-retry}"
api_url="https://api.github.com/repos/${repo}/releases/latest"

case "$(uname -s)" in
  Darwin) ;;
  *)
    echo "install.sh currently supports macOS only." >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  arm64|aarch64) target="aarch64-apple-darwin" ;;
  x86_64) target="x86_64-apple-darwin" ;;
  *)
    echo "Unsupported macOS architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

asset_name="codex-fixed-retry-${target}.tar.gz"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

release_json="$(curl -fsSL "$api_url")"
asset_url="$(printf '%s' "$release_json" | tr -d '\r' | grep -o "https://[^\"]*${asset_name}" | head -n1 || true)"

if [[ -z "$asset_url" ]]; then
  echo "Could not find release asset ${asset_name} in ${repo}" >&2
  exit 1
fi

install_root="${HOME}/.local/share/codex-fixed-retry/current"
bin_dir="${HOME}/.local/bin"
archive_path="${tmp_dir}/${asset_name}"

curl -fsSL "$asset_url" -o "$archive_path"
rm -rf "$install_root"
mkdir -p "$install_root" "$bin_dir"
tar -xzf "$archive_path" -C "$install_root"
chmod +x "${install_root}/codex"

wrapper_path="${bin_dir}/codex"
cat > "$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec "${HOME}/.local/share/codex-fixed-retry/current/codex" "$@"
EOF
chmod +x "$wrapper_path"

echo "Installed patched Codex to ${install_root}"
echo "Shim written to ${wrapper_path}"

case ":$PATH:" in
  *":${bin_dir}:"*) ;;
  *)
    echo "Add ${bin_dir} to PATH before your system Codex install if needed."
    ;;
esac
