#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root/macos/CodexAuthStatusBar"

exec swift run -c release CodexAuthStatusBar
