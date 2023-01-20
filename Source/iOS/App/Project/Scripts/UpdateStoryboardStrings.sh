#!/bin/bash
export PATH="$PATH:/opt/homebrew/bin"

set -e

cd "$PROJECT_DIR"

# Run BartyCrouch to update storyboard strings
bartycrouch update -x
