#!/usr/bin/env bash

set -euo pipefail

# Paths
PROJECT_DIR="${PROJECT_DIR:-$GH/zsh-tips-agent}"
HISTORY_FILE="$HOME/.zsh_history"
CACHE_DIR="$PROJECT_DIR/data"
TIP_FILE="$CACHE_DIR/current_tip.txt"
TIP_CACHE="$CACHE_DIR/tip_cache.json"
AGENT="$PROJECT_DIR/agent/generate_tip.py"

mkdir -p "$CACHE_DIR"

# Gather tool candidates
mapfile -t tools < <(
  {
    ls /usr/local/bin 2>/dev/null
    brew list --formula 2>/dev/null
  } | sort -u
)

# Count usage from history
declare -A usage_counts
for tool in "${tools[@]}"; do
  count=$(grep -c -w "$tool" "$HISTORY_FILE" 2>/dev/null || echo 0)
  usage_counts["$tool"]=$count
done

# Pick least-used tool
least_used=$(for k in "${!usage_counts[@]}"; do echo "${usage_counts[$k]} $k"; done | sort -n | head -n1 | cut -d' ' -f2)

# Check cache
if [[ -f "$TIP_CACHE" && $(jq -r --arg tool "$least_used" '.[$tool] // empty' "$TIP_CACHE") ]]; then
  tip=$(jq -r --arg tool "$least_used" '.[$tool]' "$TIP_CACHE")
else
  tip="🤖 Generating tip for '$least_used'..."
  echo "$tip" > "$TIP_FILE"
  # Run agent in background
  nohup python3 "$AGENT" "$least_used" "$TIP_CACHE" "$TIP_FILE" >/dev/null 2>&1 &
  exit 0
fi

# Write cached tip
echo "$tip" > "$TIP_FILE"
