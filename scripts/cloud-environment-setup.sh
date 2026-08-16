#!/usr/bin/env bash
# LOCAL AGENTS: do not execute this script unless you are running in a cloud agent environment.

set -Eeuo pipefail

readonly BACKLOG_VERSION='1.50.1'
readonly PNPM_VERSION='10.28.1'

log() {
	printf '[cloud-setup] %s\n' "$*"
}

install_system_tools() {
	local -a packages=()
	local package

	command -v curl >/dev/null 2>&1 || packages+=(curl)
	command -v git >/dev/null 2>&1 || packages+=(git)
	command -v gh >/dev/null 2>&1 || packages+=(gh)
	command -v jq >/dev/null 2>&1 || packages+=(jq)
	command -v rg >/dev/null 2>&1 || packages+=(ripgrep)

	if ((${#packages[@]} == 0)); then
		return
	fi

	if ! command -v apt-get >/dev/null 2>&1; then
		printf '[cloud-setup] ERROR: missing required tools (%s) and apt-get is unavailable.\n' \
			"${packages[*]}" >&2
		return 1
	fi

	log "Installing system tools: ${packages[*]}"
	apt-get update
	for package in "${packages[@]}"; do
		DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends "$package"
	done
}

install_node_tool() {
	local command_name=$1
	local package_name=$2
	local version=$3
	local installed_version=''

	if command -v "$command_name" >/dev/null 2>&1; then
		installed_version=$("$command_name" --version 2>/dev/null | sed -n '1{s/^v//;p;}')
	fi

	if [[ "$installed_version" == "$version" ]]; then
		return
	fi

	log "Installing ${package_name}@${version}"
	npm install --global "${package_name}@${version}"
}

find_repo_root() {
	local candidate

	for candidate in "${CODEX_ROOT:-}" "${CLAUDE_PROJECT_DIR:-}" "$PWD"; do
		if [[ -n "$candidate" ]] && git -C "$candidate" rev-parse --show-toplevel 2>/dev/null; then
			return
		fi
	done

	printf '[cloud-setup] ERROR: could not locate the checked-out repository.\n' >&2
	return 1
}

log 'Preparing the Codex/Claude cloud task environment'
install_system_tools

command -v node >/dev/null 2>&1 || {
	printf '[cloud-setup] ERROR: Node.js is required but was not found.\n' >&2
	exit 1
}
command -v npm >/dev/null 2>&1 || {
	printf '[cloud-setup] ERROR: npm is required but was not found.\n' >&2
	exit 1
}

node -e "const [major, minor] = process.versions.node.split('.').map(Number); if (major < 20 || (major === 20 && minor < 19)) process.exit(1)" || {
	printf '[cloud-setup] ERROR: Node.js 20.19 or newer is required (found %s).\n' \
		"$(node --version)" >&2
	exit 1
}

install_node_tool pnpm pnpm "$PNPM_VERSION"
install_node_tool backlog backlog.md "$BACKLOG_VERSION"

readonly REPO_ROOT=$(find_repo_root)
cd "$REPO_ROOT"

[[ -f pnpm-lock.yaml ]] || {
	printf '[cloud-setup] ERROR: pnpm-lock.yaml was not found in %s.\n' "$REPO_ROOT" >&2
	exit 1
}
[[ -f backlog/config.yml ]] || {
	printf '[cloud-setup] ERROR: Backlog.md configuration was not found in %s.\n' "$REPO_ROOT" >&2
	exit 1
}

log 'Installing locked project dependencies'
pnpm install --frozen-lockfile

log 'Verifying task and validation tooling'
backlog instructions overview >/dev/null
pnpm exec eslint --version >/dev/null
pnpm exec prettier --version >/dev/null
pnpm exec svelte-check --version >/dev/null
pnpm exec vite --version >/dev/null

log 'Cloud environment setup complete'
