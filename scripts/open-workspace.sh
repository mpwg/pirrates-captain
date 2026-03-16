#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$repo_root"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen is required but not installed." >&2
  echo "install it with: brew install xcodegen" >&2
  exit 1
fi

echo "Generating Xcode project from project.yml..."
xcodegen generate

echo "Opening workspace..."
open "$repo_root/PirratesCaptain.xcworkspace"
