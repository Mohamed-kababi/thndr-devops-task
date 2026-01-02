#!/bin/bash
# test.sh - Run application tests

# Exit on error
set -e

echo "Installing dependencies..."
pip install poetry
poetry install --no-root

echo "Running tests..."
# Add your test commands here
# For now, we just check if the app can start
export PYTHONPATH=.
python -c "from app.main import app; print('App imports successfully')"

echo "Tests completed successfully"
