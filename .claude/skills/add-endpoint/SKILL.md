---
name: add-endpoint
description: >
  新しいFastAPIエンドポイントを追加するスキル。
  CLAUDE.mdのガイドラインに従って、モデル、スキーマ、CRUD、ルーター、テストを自動生成。
  N+1クエリ回避、ページネーション、型ヒント、セキュリティ対策を自動的に組み込む。
---

# Add Endpoint Skill

CLAUDE.mdのガイドラインに従って、新しいエンドポイントを追加します。

## 使い方

ユーザーが「新しいエンドポイントを追加したい」「Postモデルを作りたい」「ブログ機能を追加して」などと言った場合に実行します。

## 生成するファイル

1. **モデル**: `app/models/{resource}.py` - SQLAlchemyモデル
2. **スキーマ**: `app/schemas/{resource}/` - Pydanticスキーマ（base.py, create.py, update.py, response.py）
3. **リポジトリ**: `app/db/repositories/{resource}.py` - BaseRepository継承、カスタムCRUD操作
4. **エンドポイント**: `app/api/v1/endpoints/{resource}s.py` - FastAPIルーター
5. **テスト**: `tests/test_api/test_{resource}s.py` - pytestテストケース
6. **マイグレーション**: `alembic/versions/xxx_add_{resource}s_table.py` - マイグレーションファイル

## 実行フロー

### 1. ユーザーに質問

以下の情報を収集します：

- **リソース名**（単数形）: 例: "post", "product", "comment"
- **フィールド一覧**:
  - フィールド名: 例: "title", "content", "price"
  - データ型: str, int, float, bool, text, datetime
  - オプション: optional（NULL許可）, unique（ユニーク制約）, index（インデックス作成）
  - 例: `title:str:unique:index`, `content:text`, `price:float`, `published:bool`
- **認証が必要か**: yes/no（認証が必要な場合、`get_current_user`依存性を追加）
- **ユーザーとの関連**: yes/no（1対多の関係、例: Postは User に属する）

### 2. モデル生成（`app/models/{resource}.py`）

**テンプレート**:

```python
"""Post model."""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.db.base import Base


class Post(Base):
    """Post model."""

    __tablename__ = "posts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), unique=True, index=True, nullable=False)
    content = Column(Text, nullable=False)
    published = Column(Boolean, default=False, nullable=False)

    # ユーザーとの関連（必要に応じて）
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user = relationship("User", back_populates="posts")

    # タイムスタンプ（必須）
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
```

**自動的に組み込む**:
- 主キー（`id`、Integer、自動インクリメント）
- タイムスタンプ（`created_at`、`updated_at`）
- インデックス（検索対象フィールド）
- 外部キー制約（ユーザーとの関連がある場合）
- リレーションシップ（`relationship()`）

### 3. スキーマ生成（`app/schemas/{resource}/`）

4つのファイルを生成：

#### `base.py` - 共通フィールド

```python
"""Post base schema."""
from pydantic import BaseModel, Field


class PostBase(BaseModel):
    """Post base schema."""

    title: str = Field(..., max_length=200, description="投稿タイトル")
    content: str = Field(..., description="投稿内容")
    published: bool = Field(default=False, description="公開状態")
```

#### `create.py` - 作成時

```python
"""Post create schema."""
from app.schemas.post.base import PostBase


class PostCreate(PostBase):
    """Post create schema."""
    pass
```

#### `update.py` - 更新時

```python
"""Post update schema."""
from typing import Optional
from pydantic import Field

from app.schemas.post.base import PostBase


class PostUpdate(BaseModel):
    """Post update schema."""

    title: Optional[str] = Field(None, max_length=200)
    content: Optional[str] = None
    published: Optional[bool] = None
```

#### `response.py` - レスポンス

```python
"""Post response schema."""
from datetime import datetime
from pydantic import ConfigDict

from app.schemas.post.base import PostBase


class PostResponse(PostBase):
    """Post response schema."""

    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
```

### 4. リポジトリ生成（`app/db/repositories/{resource}.py`）

```python
"""Post repository."""
from typing import List
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.post import Post
from app.models.user import User
from app.db.repositories.base import BaseRepository


class PostRepository(BaseRepository[Post]):
    """Post repository."""

    model = Post

    async def get_by_user_id(
        self, user_id: int, skip: int = 0, limit: int = 20
    ) -> List[Post]:
        """ユーザーIDで投稿を取得（ページネーション付き）"""
        result = await self.db.execute(
            select(Post)
            .where(Post.user_id == user_id)
            .options(selectinload(Post.user))  # N+1クエリ回避
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()

    async def get_published(
        self, skip: int = 0, limit: int = 20
    ) -> List[Post]:
        """公開済み投稿を取得"""
        result = await self.db.execute(
            select(Post)
            .where(Post.published == True)
            .options(selectinload(Post.user))
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()
```

**自動的に組み込む**:
- `BaseRepository[Post]`を継承（共通CRUD操作）
- カスタムメソッド（ユーザーIDで取得、公開済み取得など）
- `selectinload()`でN+1クエリを回避
- ページネーション（`skip`, `limit`、デフォルト20、最大100）

### 5. エンドポイント生成（`app/api/v1/endpoints/{resource}s.py`）

```python
"""Post endpoints."""
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.post.create import PostCreate
from app.schemas.post.update import PostUpdate
from app.schemas.post.response import PostResponse
from app.db.repositories.post import PostRepository
from app.core.exceptions.record_not_found import RecordNotFoundError
from app.core.exceptions.forbidden import ForbiddenError

router = APIRouter()


@router.post("/", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    post_in: PostCreate,
    current_user: User = Depends(get_current_user),  # 認証必須
    db: AsyncSession = Depends(get_db),
):
    """新しい投稿を作成"""
    repo = PostRepository(db)
    post = await repo.create({**post_in.dict(), "user_id": current_user.id})
    return post


@router.get("/", response_model=List[PostResponse])
async def list_posts(
    skip: int = 0,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """投稿一覧取得（公開済みのみ）"""
    if limit > 100:
        limit = 100
    repo = PostRepository(db)
    posts = await repo.get_published(skip=skip, limit=limit)
    return posts


@router.get("/{post_id}", response_model=PostResponse)
async def get_post(
    post_id: int,
    db: AsyncSession = Depends(get_db),
):
    """投稿取得"""
    repo = PostRepository(db)
    post = await repo.get_by_id(post_id)
    if not post:
        raise RecordNotFoundError(f"Post with id {post_id} not found")
    return post


@router.put("/{post_id}", response_model=PostResponse)
async def update_post(
    post_id: int,
    post_in: PostUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """投稿更新"""
    repo = PostRepository(db)
    post = await repo.get_by_id(post_id)
    if not post:
        raise RecordNotFoundError(f"Post with id {post_id} not found")

    # 所有者チェック
    if post.user_id != current_user.id:
        raise ForbiddenError("You are not the owner of this post")

    updated_post = await repo.update_by_id(post_id, post_in.dict(exclude_unset=True))
    return updated_post


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_post(
    post_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """投稿削除"""
    repo = PostRepository(db)
    post = await repo.get_by_id(post_id)
    if not post:
        raise RecordNotFoundError(f"Post with id {post_id} not found")

    # 所有者チェック
    if post.user_id != current_user.id:
        raise ForbiddenError("You are not the owner of this post")

    await repo.delete_by_id(post_id)
```

**自動的に組み込む**:
- 型ヒント（すべての関数）
- 非同期処理（`async def`）
- ページネーション（`skip`, `limit`）
- 認証（`get_current_user`依存性、必要に応じて）
- バリデーション（Pydanticスキーマ）
- エラーハンドリング（404, 403など）
- 所有者チェック（更新・削除時）

### 6. テスト生成（`tests/test_api/test_{resource}s.py`）

```python
"""Post API tests."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_post(auth_client: AsyncClient):
    """投稿作成のテスト"""
    response = await auth_client.post(
        "/api/v1/posts/",
        json={
            "title": "Test Post",
            "content": "This is a test post",
            "published": True
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Post"
    assert data["content"] == "This is a test post"
    assert data["published"] is True


@pytest.mark.asyncio
async def test_list_posts(client: AsyncClient):
    """投稿一覧取得のテスト"""
    response = await client.get("/api/v1/posts/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


@pytest.mark.asyncio
async def test_get_post_not_found(client: AsyncClient):
    """投稿取得（存在しない）のテスト"""
    response = await client.get("/api/v1/posts/999999")
    assert response.status_code == 404
```

### 7. ルーター登録（`app/api/v1/router.py`）

既存のルーターに追加：

```python
from app.api.v1.endpoints import auth, users, posts  # 追加

api_router.include_router(posts.router, prefix="/posts", tags=["posts"])  # 追加
```

### 8. モデルのインポート（`app/models/__init__.py`）

マイグレーションで認識されるように：

```python
from app.models.user import User
from app.models.post import Post  # 追加
```

### 9. マイグレーション生成・適用

```bash
# マイグレーションファイル生成
alembic revision --autogenerate -m "Add posts table"

# マイグレーション適用
alembic upgrade head
```

## 実行後の確認

生成が完了したら、以下を確認してください：

- [ ] `app/models/post.py` が作成された
- [ ] `app/schemas/post/` に4つのファイルが作成された
- [ ] `app/db/repositories/post.py` が作成された
- [ ] `app/api/v1/endpoints/posts.py` が作成された
- [ ] `tests/test_api/test_posts.py` が作成された
- [ ] `app/api/v1/router.py` にルーターが登録された
- [ ] `app/models/__init__.py` にモデルがインポートされた
- [ ] マイグレーションが適用された
- [ ] `http://localhost:8000/docs` でSwagger UIに新しいエンドポイントが表示される

## 次のステップ

ユーザーに以下を提案してください：

- `/security-check`: セキュリティレビュー実行
- `/performance-check`: パフォーマンスレビュー実行
- テスト実行: `./bin/test.sh`
- 新しいエンドポイントの動作確認: Swagger UIまたはcurlでテスト
