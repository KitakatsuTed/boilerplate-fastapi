#!/bin/bash
# format.sh - コードフォーマット

echo "✨ Formatting code with ruff..."
ruff format .
echo "✅ Formatting complete!"

echo ""
echo "🔍 Checking code with ruff..."
ruff check . --fix
echo "✅ Linting complete!"
