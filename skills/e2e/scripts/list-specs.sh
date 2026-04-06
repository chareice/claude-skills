#!/usr/bin/env bash
# List all e2e specs with summary info
# Usage: list-specs.sh [specs-dir]

# Auto-find specs directory
if [ -n "$1" ]; then
  SPECS_DIR="$1"
elif [ -d "e2e/specs" ]; then
  SPECS_DIR="e2e/specs"
else
  # Check for git worktree layout: look for .bare sibling and use main/
  dir="$PWD"
  while [ "$dir" != "/" ]; do
    parent=$(dirname "$dir")
    if [ -d "$parent/.bare" ] && [ -d "$parent/main/e2e/specs" ]; then
      SPECS_DIR="$parent/main/e2e/specs"
      break
    fi
    # Also check if we're at the worktree root already
    if [ -d "$dir/.bare" ] && [ -d "$dir/main/e2e/specs" ]; then
      SPECS_DIR="$dir/main/e2e/specs"
      break
    fi
    dir="$parent"
  done

  # Fallback: search upward for e2e/specs
  if [ -z "$SPECS_DIR" ]; then
    dir="$PWD"
    while [ "$dir" != "/" ]; do
      if [ -d "$dir/e2e/specs" ]; then
        SPECS_DIR="$dir/e2e/specs"
        break
      fi
      dir=$(dirname "$dir")
    done
  fi

  SPECS_DIR="${SPECS_DIR:-e2e/specs}"
fi

if [ ! -d "$SPECS_DIR" ]; then
  echo "No specs directory found at $SPECS_DIR"
  echo "Run /e2e setup to initialize."
  exit 0
fi

specs=($(find "$SPECS_DIR" -name '*.md' -type f | sort))

if [ ${#specs[@]} -eq 0 ]; then
  echo "No specs found in $SPECS_DIR"
  echo "Run /e2e write <description> to create one."
  exit 0
fi

# Header
printf "%-30s %-40s %6s %6s\n" "File" "Flow" "Steps" "Setup"
printf "%-30s %-40s %6s %6s\n" "----" "----" "-----" "-----"

total=0
for spec in "${specs[@]}"; do
  filename=$(basename "$spec")

  # Extract title from first heading
  title=$(grep -m1 '^# ' "$spec" | sed 's/^# //')
  # Truncate long titles
  if [ ${#title} -gt 38 ]; then
    title="${title:0:35}..."
  fi

  # Count steps (lines matching numbered action pattern)
  steps=$(grep -c '^\s*[0-9]\+\.\s*\*\*action' "$spec" 2>/dev/null || echo "0")

  # Check for setup section
  has_setup="no"
  grep -q '^## Setup' "$spec" && has_setup="yes"

  printf "%-30s %-40s %6s %6s\n" "$filename" "$title" "$steps" "$has_setup"
  total=$((total + 1))
done

echo ""
echo "$total specs total"
