# コーディング規約

このドキュメントでは、FastAPIボイラープレートプロジェクトで採用しているコーディング規約を説明します。一貫したコードスタイルを保つことで、保守性と可読性を向上させます。

## 📚 関連ドキュメント

- [../README.md](../README.md) - プロジェクト概要
- [../CLAUDE.md](../CLAUDE.md) - コアガイドライン

**開発環境とコーディング**
- [SETUP.md](SETUP.md) - 開発環境セットアップ

**テストと品質**
- [TESTING.md](TESTING.md) - テストの書き方
- [SECURITY.md](SECURITY.md) - セキュリティ対策

**データベースとパフォーマンス**
- [MIGRATIONS.md](MIGRATIONS.md) - マイグレーション
- [PERFORMANCE.md](PERFORMANCE.md) - パフォーマンス最適化

**ツールとデプロイ**
- [TOOLING.md](TOOLING.md) - Claude Codeスキルとscaffold.sh
- [FAQ.md](FAQ.md) - よくある質問

**アーキテクチャ**
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計

---

## 概要

このプロジェクトでは、一貫したコードスタイルを保つために以下の規約を採用しています。

## 1. Ruffによるリントとフォーマット

[Ruff](https://github.com/astral-sh/ruff)は、Python用の高速なリンター・フォーマッターです。

### 設定（`pyproject.toml`）

```toml
[tool.ruff]
line-length = 120
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4"]
ignore = ["E501"]
```

### コマンド

```bash
# リントチェック
ruff check .

# 自動修正
ruff check --fix .

# フォーマット
ruff format .

# またはシェルスクリプトを使用
./bin/format.sh
```

## 2. 型ヒント

すべての関数に型ヒントを追加してください。型ヒントにより、IDEの補完機能が向上し、バグを早期に発見できます。

### ✅ 良い例

```python
async def get_user(user_id: int, db: AsyncSession) -> User | None:
    repo = UserRepository(db)
    return await repo.get_by_id(user_id)
```

### ❌ 悪い例

```python
async def get_user(user_id, db):  # 型ヒントなし
    ...
```

## 3. 1ファイル1クラスの原則

クラスは独立したファイルに配置してください。これにより、ファイルの責任が明確になり、保守性が向上します。

### ✅ 良い例

```
app/core/exceptions/
├── business.py          # BusinessException
├── record_not_found.py  # RecordNotFoundError
└── unauthorized.py      # UnauthorizedError
```

### ❌ 悪い例

```
app/core/
└── exceptions.py  # 複数のクラスを1ファイルに詰め込む
```

## 4. Mixinを使用しない

コードの明示性を優先し、Mixinを使わず、フィールドを直接定義してください。

### ✅ 良い例

```python
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

### ❌ 悪い例

```python
class TimestampMixin:
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class User(Base, TimestampMixin):  # ❌ Mixinを使用
    ...
```

## 5. 非同期処理

すべてのI/O処理は非同期化してください。FastAPIは非同期処理をサポートしており、パフォーマンスが大幅に向上します。

### ✅ 良い例

```python
async def create_user(user_in: UserCreate, db: AsyncSession) -> User:
    repo = UserRepository(db)
    return await repo.create(user_in.dict())
```

### ❌ 悪い例

```python
def create_user(user_in: UserCreate, db: Session) -> User:  # 同期
    ...
```

## 6. ドキュメンテーション

関数には適切なdocstringを追加してください。Googleスタイルのdocstringを推奨します。

### 例

```python
async def get_user(user_id: int, db: AsyncSession) -> User | None:
    """ユーザーをIDで取得

    Args:
        user_id: ユーザーID
        db: データベースセッション

    Returns:
        Userオブジェクト、存在しない場合はNone

    Raises:
        RecordNotFoundError: ユーザーが見つからない場合
    """
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if not user:
        raise RecordNotFoundError(f"User with id {user_id} not found")
    return user
```

## 7. 命名規則

### ファイル名

- 小文字とアンダースコア（スネークケース）: `user_repository.py`
- 1ファイル1クラス: `record_not_found.py`（`RecordNotFoundError`クラス）

### クラス名

- パスカルケース: `UserRepository`, `RecordNotFoundError`

### 関数名・変数名

- スネークケース: `get_user`, `user_id`

### 定数名

- 大文字とアンダースコア: `MAX_RETRY_COUNT`, `DEFAULT_PAGE_SIZE`

## 8. インポート順序

Ruffが自動的に整理しますが、以下の順序を推奨します：

1. 標準ライブラリ
2. サードパーティライブラリ
3. ローカルアプリケーション

```python
# 標準ライブラリ
from datetime import datetime
from typing import List

# サードパーティライブラリ
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

# ローカルアプリケーション
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserCreate
```

## 9. コード品質チェック

### pre-commitフック

コミット前に自動的にRuffでフォーマットとリントが実行されます。

```bash
pre-commit install
```

### 手動チェック

```bash
# フォーマットとリントを実行
./bin/format.sh

# 型チェック（オプション）
mypy app/
```

## まとめ

- **Ruff**でリント・フォーマット
- **型ヒント**をすべての関数に追加
- **1ファイル1クラス**の原則を守る
- **Mixinを使用しない**
- **非同期処理**を優先
- **Googleスタイルのdocstring**を記述
- **スネークケース**でファイル名・関数名
- **pre-commitフック**でコード品質を保証
