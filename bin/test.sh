#!/bin/bash
# test.sh - カバレッジ付きテスト実行

echo "🧪 Running tests with coverage..."
pytest tests/ -v --cov=app --cov-report=term-missing --cov-report=html
echo ""
echo "📊 Coverage report generated: htmlcov/index.html"
