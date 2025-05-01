#!/bin/bash

set -e

VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/python3" -m pip install polib
