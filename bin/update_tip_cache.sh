#!/usr/bin/env bash
set -euo pipefail

# ---- Configurable paths ----
PROJECT_DIR="${PROJECT_DIR:-$GH/zsh-tips-agent}"
HISTORY_FILE="$HOME/.zsh_history"
CACHE_DIR="$PROJECT_DIR/data"
TIP_FILE="$CACHE_DIR/current_tip.txt"
TIP_CACHE="$CACHE_DIR/tip_cache.json"
AGENT="$PROJECT_DIR/agent/generate_tip.py"
TIP_AGE_HOURS=2    # Refresh threshold
TIP_WINDOW_DAYS=30 # Max freshness window

# ---- Flags ----
DRY_RUN=0
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
  --dry-run) DRY_RUN=1 ;;
  --verbose) VERBOSE=1 ;;
  esac
done

mkdir -p "$CACHE_DIR"
[[ -f "$TIP_CACHE" ]] || echo '{}' >"$TIP_CACHE"

# ---- Gather user-installed tool candidates ----
tools=()
for dir in ~/.local/bin /usr/local/bin /opt/homebrew/bin; do
  [[ -d "$dir" ]] || continue
  for tool in $(ls "$dir" 2>/dev/null); do
    path="$dir/$tool"
    if [[ -n "$tool" && ! -d "$path" && (-f "$path" || -L "$path") && -x "$path" ]]; then
      tools+=("$tool")
    fi
  done
done
tools=($(printf "%s\n" "${tools[@]}" | sort -u))

if [[ ${#tools[@]} -eq 0 ]]; then
  echo "No tool candidates found for tips." >"$TIP_FILE"
  exit 0
fi

# ---- Count usage from history ----
tmp_usage=$(mktemp)
for tool in "${tools[@]}"; do
  count=$(grep -c -w "$tool" "$HISTORY_FILE" 2>/dev/null || echo 0)
  printf '%s %s\n' "$count" "$tool" >>"$tmp_usage"
  [[ "$VERBOSE" = true ]] && echo "Usage count: $count  Tool: $tool" >&2
done

# ---- Build usage tiers using files ----
usage_groups_dir=$(mktemp -d)
sorted_counts=()

while read -r count tool; do
  [[ -z "$tool" ]] && continue
  echo "$tool" >>"$usage_groups_dir/$count"
done <"$tmp_usage"
rm -f "$tmp_usage"

sorted_counts=($(find "$usage_groups_dir" -type f -exec basename {} \; | sort -n))

# ---- Select tip candidate with freshness filtering ----
now=$(date +%s)
recent_secs=$((TIP_AGE_HOURS * 3600))
window_secs=$(( TIP_WINDOW_DAYS * 24 * 3600 ))

pick=""
for usage in "${sorted_counts[@]}"; do
  tools_in_tier_file="$usage_groups_dir/$usage"
  [[ -f "$tools_in_tier_file" ]] || continue
  tools_in_tier=()
  while IFS= read -r tool; do
    tools_in_tier+=( "$tool" )
  done < "$tools_in_tier_file"
  
  if ((VERBOSE)); then
    echo "Tier usage count = $usage: ${tools_in_tier[*]}"
  fi

  # Build eligible list once per tier
  eligible=()
  for tool in "${tools_in_tier[@]}"; do
    [[ -z "$tool" ]] && continue
    last_shown=$(jq -r --arg t "$tool" '.[$t].last_shown // 0' "$TIP_CACHE")
    age=$((now - last_shown))
    if (( last_shown == 0 || ( age >= recent_secs && age <= window_secs ) )); then
      eligible+=( "$tool" )
    fi
  done

  # If we found any eligible tools, pick the one shown the longest ago and stop
  if (( ${#eligible[@]} > 0 )); then
    oldest_tool=""
    oldest_time=$now
    for tool in "${eligible[@]}"; do
      t_last=$(jq -r --arg t "$tool" '.[$t].last_shown // 0' "$TIP_CACHE")
      if (( t_last < oldest_time )); then
        oldest_time=$t_last
        oldest_tool="$tool"
      fi
    done
    pick="$oldest_tool"
    break
  fi
done
if [[ -z "$pick" ]]; then
  fallback_file="$usage_groups_dir/${sorted_counts[0]}"
  oldest_tool=""
  oldest_time=$now

  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    last_shown=$(jq -r --arg t "$tool" '.[$t].last_shown // 0' "$TIP_CACHE")
    if ((last_shown < oldest_time)); then
      oldest_time=$last_shown
      oldest_tool="$tool"
    fi
  done <"$fallback_file"

  pick="$oldest_tool"
fi

rm -rf "$usage_groups_dir"

if ((VERBOSE)); then
  echo "Selected tool: $pick"
fi

# ---- Show or generate tip ----
if [[ -f "$TIP_CACHE" && $(jq -r --arg t "$pick" '.[$t].tip // empty' "$TIP_CACHE") ]]; then
  tip=$(jq -r --arg t "$pick" '.[$t].tip' "$TIP_CACHE")
  echo "$tip" >"$TIP_FILE"
else
  if ((DRY_RUN)); then
    echo "[dry-run] python3 $AGENT $pick $TIP_CACHE $TIP_FILE"
  else
    "$PROJECT_DIR/.venv/bin/python" "$AGENT" "$pick" "$TIP_CACHE" "$TIP_FILE"
  fi
fi
