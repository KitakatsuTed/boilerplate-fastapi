# パフォーマンス最適化

このドキュメントでは、FastAPIボイラープレートプロジェクトでのパフォーマンス最適化のベストプラクティスを説明します。

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
- [MIGRATIONS.md](MIGRATIONS.md) - マイグレーション

**ツールとデプロイ**
- [TOOLING.md](TOOLING.md) - Claude Codeスキルとscaffold.sh
- [FAQ.md](FAQ.md) - よくある質問

**アーキテクチャ**
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計

---

## 概要

このプロジェクトでは、以下のパフォーマンス最適化を実装しています：

1. N+1クエリの回避
2. ページネーション
3. 接続プール設定
4. インデックス戦略
5. キャッシング

## 1. N+1クエリの回避

N+1クエリは、最も一般的なパフォーマンスの問題です。`selectinload()`または`joinedload()`を使用して回避します。

### ❌ 悪い例（N+1クエリ）

```python
# 100件のユーザーに対して101回のクエリ
users = await db.execute(select(User).limit(100))
for user in users.scalars():
    posts = await db.execute(select(Post).where(Post.user_id == user.id))
    # 100回のクエリが実行される
```

### ✅ 良い例（selectinloadで1回のクエリ）

```python
from sqlalchemy.orm import selectinload

users = await db.execute(
    select(User)
    .options(selectinload(User.posts))
    .limit(100)
)
# 1回のクエリで全ての投稿を取得
```

### selectinload vs joinedload

| 方式           | 用途                               | クエリ数 |
|----------------|------------------------------------|----------|
| `selectinload` | 1対多リレーション（推奨）          | 2回      |
| `joinedload`   | 多対1リレーション                  | 1回      |
| 使い分け       | selectinloadは大量データに適している | -        |

## 2. ページネーション

大量のデータを一度に取得しないよう、必ず`limit`と`offset`を使用します。

### ページネーション実装

```python
@router.get("/posts/", response_model=List[PostResponse])
async def list_posts(
    skip: int = 0,
    limit: int = 20,  # デフォルト20、最大100
    db: AsyncSession = Depends(get_db),
):
    """投稿一覧取得"""
    if limit > 100:
        limit = 100
    repo = PostRepository(db)
    posts = await repo.get_all(skip=skip, limit=limit)
    return posts
```

### ベストプラクティス

- **デフォルト値**: 20件
- **最大値**: 100件
- **全件取得を避ける**: `.all()`を使わない

## 3. 接続プール設定

適切な接続プール設定により、データベース接続のオーバーヘッドを削減します。

### 推奨設定

```python
# app/db/session.py
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=10,        # 推奨: 同時接続数（CPU数 × 2が目安）
    max_overflow=20,     # 推奨: pool_sizeの2倍
    pool_pre_ping=True,  # 推奨: 接続確認（タイムアウト対策）
)
```

### パラメータ説明

| パラメータ       | 説明                                | 推奨値      |
|------------------|-------------------------------------|-------------|
| `pool_size`      | 同時に保持する接続数                | CPU数 × 2   |
| `max_overflow`   | pool_sizeを超えた場合の追加接続数   | pool_size × 2 |
| `pool_pre_ping`  | 接続確認（タイムアウト対策）        | True        |

## 4. インデックス戦略

適切なインデックスにより、クエリパフォーマンスが大幅に向上します。

### インデックスが必要なカラム

- **検索対象**: `WHERE`句で使用するカラム
- **ソート対象**: `ORDER BY`で使用するカラム
- **外部キー**: リレーションシップのカラム
- **ユニークキー**: `email`、`username`等

### 例: インデックス追加

```python
# app/models/user.py
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)  # 主キーインデックス
    email = Column(String(255), unique=True, index=True, nullable=False)  # ユニークインデックス
    created_at = Column(DateTime, default=datetime.utcnow, index=True)  # ソート用インデックス
```

### 複合インデックス

複数のカラムを組み合わせたインデックスも有効です。

```python
# マイグレーションファイル
def upgrade() -> None:
    op.create_index(
        "idx_posts_user_id_created_at",
        "posts",
        ["user_id", "created_at"]
    )
```

## 5. クエリ最適化

効率的なクエリを記述することで、パフォーマンスが向上します。

### 必要なカラムのみ取得

```python
# ❌ すべてのカラムを取得
result = await db.execute(select(User))

# ✅ 必要なカラムのみ取得
result = await db.execute(
    select(User.id, User.email, User.full_name)
)
```

### カウントクエリの最適化

```python
# ❌ 遅い
count = len((await db.execute(select(User))).scalars().all())

# ✅ 速い
count = (await db.execute(select(func.count()).select_from(User))).scalar()
```

## 6. キャッシング戦略

頻繁にアクセスされるデータはキャッシュします。

### Redis キャッシング（オプション）

```python
from redis import asyncio as aioredis

# Redisクライアント
redis = await aioredis.from_url("redis://localhost")

# キャッシュから取得
cached = await redis.get(f"user:{user_id}")
if cached:
    return json.loads(cached)

# データベースから取得してキャッシュに保存
user = await repo.get_by_id(user_id)
await redis.setex(f"user:{user_id}", 3600, json.dumps(user.dict()))
```

## 7. パフォーマンス測定

### ロードテスト（Locust）

```python
# locustfile.py
from locust import HttpUser, task, between

class FastAPIUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def get_posts(self):
        self.client.get("/api/v1/posts/")

    @task
    def get_users(self):
        self.client.get("/api/v1/users/")
```

```bash
# ロードテスト実行
locust -f locustfile.py --host=http://localhost:8000
```

### プロファイリング（py-spy）

```bash
# アプリケーション実行中にプロファイリング
py-spy top --pid <PID>

# フレームグラフ生成
py-spy record --pid <PID> --output profile.svg
```

## まとめ

- **N+1クエリを回避**: `selectinload()`で関連データを一度に取得
- **ページネーション**: デフォルト20件、最大100件
- **接続プール**: pool_size=10、max_overflow=20
- **インデックス**: 検索・ソート対象カラムに追加
- **キャッシング**: Redisで頻繁にアクセスされるデータをキャッシュ
- **パフォーマンス測定**: Locust、py-spyで測定

## 次のステップ

パフォーマンス最適化を実装したら：

- [TOOLING.md](TOOLING.md) - `/performance-check`スキルでパフォーマンスレビュー
