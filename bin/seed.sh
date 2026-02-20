#!/bin/bash
# seed.sh - サンプルデータ投入

echo "🌱 Seeding database..."
python -m app.db.seed
echo "✅ Seeding complete!"
