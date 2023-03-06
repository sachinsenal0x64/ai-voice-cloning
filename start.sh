#!/bin/bash
if [ ! -d "venv" ]; then ./setup-guided.sh; fi

source ./venv/bin/activate
python3 ./src/main.py "$@"
deactivate
