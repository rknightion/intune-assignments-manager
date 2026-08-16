#!/usr/bin/env bash
# Manual environment setup for Codex Cloud and Claude Code cloud environments.
# Configure either service's setup script as: bash scripts/cloud-setup.sh

set -Eeuo pipefail

readonly PNPM_VERSION='10.28.1'
readonly BACKLOG_VERSION='1.50.1'

log() {
	printf '\n[cloud-setup] %s\n' "$*"
}

find_repo_root() {
	if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
		printf '%s\n' "$git_root"
		return
	fi

	# Also support direct invocation when the caller is not in the checkout root.
	cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
	pwd -P
}

install_pnpm() {
	if command -v corepack >/dev/null 2>&1; then
		corepack enable
		corepack prepare "pnpm@${PNPM_VERSION}" --activate
	else
		npm install --global "pnpm@${PNPM_VERSION}"
	fi
}

log 'Locating the repository checkout'
readonly REPO_ROOT="$(find_repo_root)"
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

log "Installing Backlog.md ${BACKLOG_VERSION}"
npm install --global "backlog.md@${BACKLOG_VERSION}"

log 'Installing project dependencies from pnpm-lock.yaml'
pnpm install --frozen-lockfile

log 'Verifying the cloud task toolchain'
printf 'Node.js:    %s\n' "$(node --version)"
printf 'pnpm:      %s\n' "$(pnpm --version)"
printf 'Backlog.md: %s\n' "$(backlog --version)"
backlog instructions overview >/dev/null
pnpm exec svelte-kit sync

log 'Environment setup complete'
