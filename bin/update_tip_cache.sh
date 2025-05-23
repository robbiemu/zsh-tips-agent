#!/usr/bin/env bash
set -euo pipefail

# ---- Configurable paths ----
PROJECT_DIR="${PROJECT_DIR:-$GH/zsh-tips-agent}"
HISTORY_FILE="$HOME/.zsh_history"
CACHE_DIR="$PROJECT_DIR/data"
TIP_FILE="$CACHE_DIR/current_tip.txt"
TIP_CACHE="$CACHE_DIR/tip_cache.json"
AGENT="$PROJECT_DIR/agent/generate_tip.py"

mkdir -p "$CACHE_DIR"

# ---- Gather tool candidates ----
tools=()
while IFS= read -r tool; do
  [[ -n "$tool" ]] && tools+=("$tool")
done < <(
  {
    ls ~/.local/bin 2>/dev/null
    ls /usr/local/bin 2>/dev/null
    brew list --formula 2>/dev/null
  } | sort -u | grep -v '^$'
)

if [[ ${#tools[@]} -eq 0 ]]; then
  echo "No tool candidates found for tips." > "$TIP_FILE"
  exit 0
fi

# ---- Count usage from history ----
tmp_usage=$(mktemp)
for tool in "${tools[@]}"; do
  [[ -z "$tool" ]] && continue
  count=$(grep -c -w "$tool" "$HISTORY_FILE" 2>/dev/null || echo 0)
  printf '%s %s\n' "$count" "$tool" >> "$tmp_usage"
done

# ---- Pick least-used tool ----
least_used=$(sort -n "$tmp_usage" | awk '{print $2}' | grep -v '^$' | head -n1)
rm -f "$tmp_usage"

if [[ -z "$least_used" ]]; then
  echo "No tool candidates found for tips." > "$TIP_FILE"
  exit 0
fi

# ---- Show or generate the tip ----
if [[ -f "$TIP_CACHE" && $(jq -r --arg tool "$least_used" '.[$tool] // empty' "$TIP_CACHE") ]]; then
  tip=$(jq -r --arg tool "$least_used" '.[$tool]' "$TIP_CACHE")
  echo "$tip" > "$TIP_FILE"
else
  # Only write the "generating" placeholder if TIP_FILE does not already exist.
  if [[ ! -f "$TIP_FILE" ]]; then
    echo "🤖 Generating tip for '$least_used'..." > "$TIP_FILE"
  fi
  nohup python3 "$AGENT" "$least_used" "$TIP_CACHE" "$TIP_FILE" >/dev/null 2>&1 &
  exit 0
fi

# ---- Output the tip ----
echo "$tip" > "$TIP_FILE"
