# データベースマイグレーション

このドキュメントでは、FastAPIボイラープレートプロジェクトでのデータベースマイグレーションの管理方法を説明します。Alembicを使用してデータベーススキーマの変更を管理します。

## 📚 関連ドキュメント

- [../README.md](../README.md) - プロジェクト概要
- [../CLAUDE.md](../CLAUDE.md) - コアガイドライン

**開発環境とコーディング**
- [SETUP.md](SETUP.md) - 開発環境セットアップ
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - コーディング規約

**テストと品質**
- [TESTING.md](TESTING.md) - テストの書き方
- [SECURITY.md](SECURITY.md) - セキュリティ対策

**データベースとパフォーマンス**
- [PERFORMANCE.md](PERFORMANCE.md) - パフォーマンス最適化

**ツールとデプロイ**
- [TOOLING.md](TOOLING.md) - Claude Codeスキルとscaffold.sh
- [FAQ.md](FAQ.md) - よくある質問

**アーキテクチャ**
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計

---

## 概要

このプロジェクトでは、**Alembic**を使用してデータベースマイグレーションを管理します。Alembicはデータベーススキーマの変更を追跡し、バージョン管理します。

## 1. 自動マイグレーション

Alembicは、SQLAlchemyモデルの変更を検出して、自動的にマイグレーションファイルを生成できます。

### モデル変更後のマイグレーション

```bash
# モデル変更後、自動でマイグレーションファイル生成
alembic revision --autogenerate -m "Add bio column to users"

# マイグレーション適用
alembic upgrade head

# ロールバック
alembic downgrade -1
```

### 例: ユーザーモデルにカラム追加

```python
# app/models/user.py
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False)
    bio = Column(Text, nullable=True)  # 新しいカラム追加
```

```bash
# マイグレーションファイル生成
alembic revision --autogenerate -m "Add bio column to users table"

# マイグレーション適用
alembic upgrade head
```

## 2. 手動マイグレーション

複雑なスキーマ変更や、autogenerateが検出できない変更は手動でマイグレーションを記述します。

### 例: インデックス追加

```python
# alembic/versions/xxx_add_email_index.py
"""Add email index to users table

Revision ID: abc123
Revises: def456
Create Date: 2024-01-20 10:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'abc123'
down_revision = 'def456'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Upgrade database schema."""
    op.create_index("idx_users_email", "users", ["email"])


def downgrade() -> None:
    """Downgrade database schema."""
    op.drop_index("idx_users_email", "users")
```

## 3. マイグレーション履歴確認

```bash
# 現在のマイグレーション状態を確認
alembic current

# マイグレーション履歴を確認
alembic history

# 詳細な履歴を確認
alembic history --verbose
```

## 4. マイグレーションの適用とロールバック

### マイグレーション適用

```bash
# 最新のマイグレーションまで適用
alembic upgrade head

# 特定のリビジョンまで適用
alembic upgrade abc123

# 1つ進める
alembic upgrade +1
```

### ロールバック

```bash
# 1つ戻す
alembic downgrade -1

# 特定のリビジョンまで戻す
alembic downgrade abc123

# すべて戻す（注意：データが失われる）
alembic downgrade base
```

## 5. マイグレーションファイルの編集

autogenerateで生成されたマイグレーションファイルは、必要に応じて編集できます。

### 例: デフォルト値の追加

```python
def upgrade() -> None:
    """Upgrade database schema."""
    op.add_column(
        "users",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true())
    )
```

## 6. トラブルシューティング

### マイグレーションが検出されない

```bash
# モデルが正しくインポートされているか確認
# app/models/__init__.py に新しいモデルをインポート
from app.models.user import User
from app.models.post import Post  # 追加したモデル
```

### マイグレーションの競合

```bash
# 複数のブランチでマイグレーションファイルが生成された場合
alembic merge heads -m "Merge migrations"
```

### データベースをリセット

```bash
# データベースをリセット（開発環境のみ）
./bin/reset_db.sh
```

## 7. マイグレーションのベストプラクティス

### ✅ 推奨事項

- **小さな変更に分割**: 1つのマイグレーションで1つの変更
- **明確な説明**: `-m`オプションで分かりやすいメッセージを記述
- **テスト**: マイグレーション適用前にローカル環境でテスト
- **ロールバック可能**: `downgrade()`を必ず実装
- **本番環境では慎重に**: バックアップを取ってから適用

### ❌ 避けるべき事項

- autogenerateに完全に依存（手動確認必須）
- ロールバック不可能なマイグレーション
- 本番環境で直接マイグレーション実行（ステージング環境で検証）

## 8. 本番環境でのマイグレーション

### 推奨手順

1. **ステージング環境でテスト**
   ```bash
   alembic upgrade head
   ```

2. **データベースのバックアップ**
   ```bash
   pg_dump -U postgres -d fastapi_db > backup.sql
   ```

3. **本番環境でマイグレーション適用**
   ```bash
   alembic upgrade head
   ```

4. **動作確認**
   ```bash
   # アプリケーションが正常に動作するか確認
   curl http://localhost:8000/health
   ```

## まとめ

- **Alembic**でデータベースマイグレーションを管理
- **autogenerate**でモデル変更を自動検出
- **手動マイグレーション**で複雑な変更に対応
- **ロールバック**でスキーマを戻せる
- **本番環境では慎重に**バックアップを取ってから適用

## 次のステップ

マイグレーションを実行したら：

- [ARCHITECTURE.md](ARCHITECTURE.md) - データベース層の設計
- [FAQ.md](FAQ.md) - マイグレーション関連のFAQ
