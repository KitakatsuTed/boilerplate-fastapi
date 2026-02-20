---
name: add-model
description: >
  新しいデータベースモデルを追加するスキル。
  SQLAlchemyモデル、Pydanticスキーマ、Alembicマイグレーションを自動生成。
  リレーションシップ、インデックス、制約を適切に設定。
---

# Add Model Skill

新しいデータベースモデルを追加します（エンドポイントなし）。

## 使い方

ユーザーが「Commentモデルを追加したい」「新しいテーブルを作りたい」「データベースモデルを追加して」などと言った場合に実行します。

**注**: エンドポイントも一緒に作成したい場合は、`/add-endpoint`スキルを使用してください。

## 生成するファイル

1. **モデル**: `app/models/{model}.py` - SQLAlchemyモデル
2. **スキーマ**: `app/schemas/{model}.py` - Pydanticスキーマ
3. **マイグレーション**: `alembic/versions/xxx_add_{model}s_table.py` - マイグレーションファイル

## 実行フロー

### 1. ユーザーに質問

以下の情報を収集します：

- **モデル名**（単数形）: 例: "comment", "category", "tag"
- **フィールド一覧**:
  - フィールド名: 例: "content", "name", "color"
  - データ型: str, int, float, bool, text, datetime
  - 制約: nullable（NULL許可）, unique（ユニーク制約）, index（インデックス作成）
  - 例: `content:text`, `name:str:unique:index`, `color:str:optional`
- **他のモデルとのリレーション**: yes/no
  - リレーション先モデル: 例: "User", "Post"
  - リレーションタイプ: 1対多、多対1、多対多
  - 例: "CommentはPostに属する（多対1）"

### 2. モデル生成（`app/models/{model}.py`）

**テンプレート**:

```python
"""Comment model."""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.db.base import Base


class Comment(Base):
    """Comment model."""

    __tablename__ = "comments"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(Text, nullable=False)

    # リレーションシップ（必要に応じて）
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    post = relationship("Post", back_populates="comments")

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    user = relationship("User", back_populates="comments")

    # タイムスタンプ（必須）
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
```

**自動的に設定する項目**:

- **主キー**: `id`、Integer、自動インクリメント
- **インデックス**: 検索対象フィールドに`index=True`
- **外部キー制約**: リレーションシップがある場合
  - `ondelete="CASCADE"`: 親が削除されたら子も削除
  - `ondelete="SET NULL"`: 親が削除されたら NULL に設定（optional フィールドのみ）
- **NOT NULL制約**: 必須フィールドに`nullable=False`
- **UNIQUE制約**: 重複不可フィールドに`unique=True`（例: email）
- **タイムスタンプ**: `created_at`, `updated_at`（必須）

### 3. リレーションシップの逆参照を設定

リレーション先のモデルに`back_populates`を追加します。

**例**: CommentがPostに属する場合

#### 既存のPostモデルに追加（`app/models/post.py`）

```python
class Post(Base):
    __tablename__ = "posts"

    # ... 既存のフィールド

    # 逆参照を追加
    comments = relationship("Comment", back_populates="post")
```

### 4. スキーマ生成（`app/schemas/{model}.py`）

```python
"""Comment schema."""
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class CommentBase(BaseModel):
    """Comment base schema."""

    content: str = Field(..., description="コメント内容")


class CommentCreate(CommentBase):
    """Comment create schema."""

    post_id: int = Field(..., description="投稿ID")


class CommentUpdate(BaseModel):
    """Comment update schema."""

    content: str | None = Field(None, description="コメント内容")


class CommentResponse(CommentBase):
    """Comment response schema."""

    id: int
    post_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
```

### 5. モデルのインポート（`app/models/__init__.py`）

マイグレーションで認識されるように：

```python
from app.models.user import User
from app.models.post import Post
from app.models.comment import Comment  # 追加
```

### 6. マイグレーション生成・適用

```bash
# マイグレーションファイル生成
alembic revision --autogenerate -m "Add comments table"

# マイグレーション適用
alembic upgrade head
```

**生成されるマイグレーション例**:

```python
"""Add comments table

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
    op.create_table(
        'comments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('post_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_comments_id'), 'comments', ['id'], unique=False)


def downgrade() -> None:
    """Downgrade database schema."""
    op.drop_index(op.f('ix_comments_id'), table_name='comments')
    op.drop_table('comments')
```

## 実行後の確認

生成が完了したら、以下を確認してください：

- [ ] `app/models/comment.py` が作成された
- [ ] `app/schemas/comment.py` が作成された
- [ ] リレーション先のモデル（例: Post, User）に逆参照が追加された
- [ ] `app/models/__init__.py` にモデルがインポートされた
- [ ] マイグレーションが適用された
- [ ] データベースにテーブルが作成されたことを確認:
  ```bash
  # PostgreSQLの場合
  docker-compose exec postgres psql -U postgres -d fastapi_db -c "\dt"
  ```

## 高度なリレーションシップ

### 多対多リレーションシップ

**例**: PostとTagの多対多リレーション

#### 中間テーブル（`app/models/post_tag.py`）

```python
"""Post-Tag association table."""
from sqlalchemy import Column, Integer, ForeignKey, Table

from app.db.base import Base

post_tags = Table(
    'post_tags',
    Base.metadata,
    Column('post_id', Integer, ForeignKey('posts.id', ondelete='CASCADE')),
    Column('tag_id', Integer, ForeignKey('tags.id', ondelete='CASCADE'))
)
```

#### Tagモデル（`app/models/tag.py`）

```python
"""Tag model."""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.models.post_tag import post_tags


class Tag(Base):
    """Tag model."""

    __tablename__ = "tags"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # 多対多リレーション
    posts = relationship("Post", secondary=post_tags, back_populates="tags")
```

#### Postモデルに追加

```python
from app.models.post_tag import post_tags

class Post(Base):
    # ... 既存のフィールド

    # 多対多リレーション
    tags = relationship("Tag", secondary=post_tags, back_populates="posts")
```

## 次のステップ

モデルのみを追加した場合、エンドポイントはまだ作成されていません。

ユーザーに以下を提案してください：

- **エンドポイントも作成する**: `/add-endpoint`スキルを実行
- **リポジトリを手動で作成**: `app/db/repositories/comment.py`
- **テストを手動で作成**: `tests/test_api/test_comments.py`
- **マイグレーションの確認**: `alembic history` でマイグレーション履歴を確認
