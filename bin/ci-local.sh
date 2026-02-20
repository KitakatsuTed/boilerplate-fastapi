#!/bin/bash
# ci-local.sh - ローカルでCI相当のチェック実行

echo "🔍 Running CI checks locally..."
echo ""

# Ruff format check
echo "📝 Checking code formatting..."
ruff format --check .
if [ $? -ne 0 ]; then
    echo "❌ Code formatting check failed!"
    echo "   Run: ./bin/format.sh"
    exit 1
fi
echo "✅ Code formatting OK"
echo ""

# Ruff lint check
echo "🔍 Running linter..."
ruff check .
if [ $? -ne 0 ]; then
    echo "❌ Linter check failed!"
    echo "   Run: ./bin/format.sh"
    exit 1
fi
echo "✅ Linter OK"
echo ""

# Tests
echo "🧪 Running tests..."
pytest tests/ -v --cov=app
if [ $? -ne 0 ]; then
    echo "❌ Tests failed!"
    exit 1
fi
echo "✅ Tests OK"
echo ""

echo "🎉 All CI checks passed!"
