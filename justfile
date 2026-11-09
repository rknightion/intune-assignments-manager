set shell := ["bash", "-euo", "pipefail", "-c"]

# Placeholder Entra client ID — $env/static/public needs a value to resolve at
# type-check/build time. The real value is per-deployment Cloudflare Pages
# config; this app is client-side only with no server secrets. Override with a
# real value via `.env` (loaded by Vite) for `just dev`.
export PUBLIC_ENTRA_CLIENT_ID := env('PUBLIC_ENTRA_CLIENT_ID', '00000000-0000-0000-0000-000000000000')

# show the task surface
default:
    @just --list

# install dependencies from the committed lockfile (idempotent)
setup:
    pnpm install --frozen-lockfile
    pnpm exec svelte-kit sync

# format source in place (prettier)
[group('check')]
fmt:
    pnpm exec prettier --write .

# verify formatting — prettier + just's own formatter
[group('check')]
[no-exit-message]
fmt-check:
    pnpm exec prettier --check .
    just --fmt --check

# static analysis (eslint)
[group('check')]
[no-exit-message]
lint:
    pnpm exec eslint .

# type-check (svelte-check via svelte-kit sync)
[group('check')]
[no-exit-message]
typecheck:
    pnpm exec svelte-kit sync
    pnpm exec svelte-check --tsconfig ./tsconfig.json

# no test suite in this repo (client-side app, no test framework configured)
[group('check')]
test filter="":
    @echo "no tests in this repo"

# the full PR gate — exactly what CI enforces
[group('check')]
check: fmt-check lint typecheck test

# production build to .svelte-kit/cloudflare
[group('build')]
[no-exit-message]
build:
    pnpm exec vite build

# remove build output and caches (reproducible via setup + build)
[confirm('remove .svelte-kit, build/, .wrangler/ and node_modules? [y/N]')]
[group('build')]
clean:
    rm -rf .svelte-kit build .wrangler node_modules

# start the Vite dev server (long-running)
[group('dev')]
dev:
    pnpm exec vite dev

# GitHub issues and the rknightion Project; maintainers only (needs the tracker tools and credentials)
[group('tracker')]
[positional-arguments]
tracker *args:
    #!/usr/bin/env bash
    set -euo pipefail
    export TRACKER_REPO=rknightion/intune-assignments-manager TRACKER_PROJECT_OWNER=rknightion TRACKER_PROJECT=7
    export TRACKER_ISSUE_IDENTITY=app TRACKER_PROJECT_IDENTITY=user
    exec tracker-with-token "$@"

# print the issue a legacy board id (ASM-0001) became
[group('tracker')]
issue id:
    TRACKER_REPO=rknightion/intune-assignments-manager tracker legacy {{ quote(id) }}
