#!/bin/bash
# reset_db.sh - データベースリセット（削除、作成、マイグレーション、Seed）

echo "⚠️  WARNING: This will delete all data in the database!"
read -p "Are you sure? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo "🗑️  Dropping all tables..."
alembic downgrade base

echo "📝 Running migrations..."
alembic upgrade head

echo "🌱 Seeding database..."
python -m app.db.seed

echo "✅ Database reset complete!"
