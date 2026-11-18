#!/usr/bin/env bash
# CLOUD AGENTS ONLY: Local agents must not execute this script.
# Dependency setup for cloud agents. Codex Cloud and Claude Code can run this
# script directly. Cursor Cloud runs it through `just cloud-bootstrap`.

set -Eeuo pipefail

readonly PNPM_VERSION='12.21.0'
readonly PNPM_PREFIX="$HOME/.local"
export PATH="$PNPM_PREFIX/bin:$PATH"
export npm_config_registry=https://registry.npmjs.org

log() {
	printf '\n[cloud-setup] %s\n' "$*"
}

find_repo_root() {
	local script_dir git_root
	script_dir="$(dirname -- "${BASH_SOURCE[0]}")"

	if git_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)"; then
		printf '%s\n' "$git_root"
		return
	fi

	# Also support direct invocation when the caller is not in the checkout root.
	cd -- "$script_dir/.." || exit 1
	pwd -P
}

install_pnpm() {
	local pnpm_bin="$PNPM_PREFIX/bin/pnpm"
	if [[ ! -x "$pnpm_bin" ]] || [[ "$("$pnpm_bin" --version)" != "$PNPM_VERSION" ]]; then
		npm install --global --prefix "$PNPM_PREFIX" --ignore-scripts --no-audit --no-fund "pnpm@$PNPM_VERSION"
	fi
}

log 'Locating the repository checkout'
REPO_ROOT="$(find_repo_root)"
readonly REPO_ROOT
cd -- "$REPO_ROOT"
printf 'Repository: %s\n' "$REPO_ROOT"

command -v node >/dev/null 2>&1 || {
	printf 'Error: Node.js is required but is not installed.\n' >&2
	exit 1
}
command -v npm >/dev/null 2>&1 || {
	printf 'Error: npm is required but is not installed.\n' >&2
	exit 1
}

log "Activating pnpm ${PNPM_VERSION}"
install_pnpm

log 'Installing project dependencies from pnpm-lock.yaml'
CI=true pnpm install --frozen-lockfile </dev/null

log 'Verifying the cloud task toolchain'
printf 'Node.js:    %s\n' "$(node --version)"
printf 'pnpm:      %s\n' "$(pnpm --version)"
pnpm exec svelte-kit sync

log 'Environment setup complete'
