#!/bin/bash
# migrate.sh - マイグレーション実行

COMMAND=${1:-upgrade}
VERSION=${2:-head}

case "$COMMAND" in
    upgrade)
        echo "⬆️  Running migration upgrade to $VERSION..."
        alembic upgrade "$VERSION"
        ;;
    downgrade)
        echo "⬇️  Running migration downgrade to $VERSION..."
        alembic downgrade "$VERSION"
        ;;
    revision)
        MESSAGE=${2:-"Auto-generated migration"}
        echo "📝 Creating new migration: $MESSAGE"
        alembic revision --autogenerate -m "$MESSAGE"
        ;;
    current)
        echo "📍 Current migration:"
        alembic current
        ;;
    history)
        echo "📜 Migration history:"
        alembic history
        ;;
    *)
        echo "Usage: $0 {upgrade|downgrade|revision|current|history} [version|message]"
        echo ""
        echo "Examples:"
        echo "  $0 upgrade head      # Upgrade to latest"
        echo "  $0 downgrade -1      # Downgrade one step"
        echo "  $0 revision \"Add users table\""
        echo "  $0 current"
        echo "  $0 history"
        exit 1
        ;;
esac
