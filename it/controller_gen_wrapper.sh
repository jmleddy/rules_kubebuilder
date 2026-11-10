#!/usr/bin/env bash
set -euo pipefail

# Exercise an executable tool whose controller-gen binary is in its runfiles.
generator="$(find -L "$0.runfiles" -type f -name controller-gen -print -quit)"
exec "$generator" "$@"
