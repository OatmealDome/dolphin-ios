#!/bin/bash

set -e

cd "$PROJECT_DIR"

# Run BartyCrouch to update storyboard strings
bartycrouch update -x
