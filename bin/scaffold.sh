#!/bin/bash
# scaffold.sh - モデル、スキーマ、リポジトリ、エンドポイント、マイグレーションを一括生成

# 使用例:
# ./bin/scaffold.sh post title:str content:text published:bool
# ./bin/scaffold.sh product name:str:unique:index sku:str:unique price:float stock:int description:text:optional published:bool

# 引数チェック
if [ $# -lt 2 ]; then
    echo "Usage: $0 <model_name> <field1:type[:options]> [field2:type[:options]] ..."
    echo ""
    echo "Supported types: str, text, int, float, bool, datetime"
    echo "Supported options: optional, unique, index"
    echo ""
    echo "Example: $0 post title:str content:text published:bool"
    exit 1
fi

MODEL_NAME=$1
shift
FIELDS=("$@")

# 大文字・小文字変換用
MODEL_CLASS=$(echo "$MODEL_NAME" | sed 's/^\(.\)/\U\1/')
MODEL_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')
MODEL_PLURAL="${MODEL_LOWER}s"

# ディレクトリ作成
mkdir -p "app/models"
mkdir -p "app/schemas/${MODEL_LOWER}"
mkdir -p "app/db/repositories"
mkdir -p "app/api/v1/endpoints"
mkdir -p "tests/test_api"

echo "🚀 Generating scaffold for ${MODEL_CLASS}..."
echo ""

# ======================================
# 1. モデル生成 (app/models/${MODEL_LOWER}.py)
# ======================================
cat > "app/models/${MODEL_LOWER}.py" <<EOF
"""${MODEL_CLASS} model."""
from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String, Text
from app.db.base import Base


class ${MODEL_CLASS}(Base):
    """${MODEL_CLASS} model."""

    __tablename__ = "${MODEL_PLURAL}"

    id = Column(Integer, primary_key=True, index=True)
EOF

# フィールドを生成
for field_spec in "${FIELDS[@]}"; do
    IFS=':' read -ra parts <<< "$field_spec"
    field_name="${parts[0]}"
    field_type="${parts[1]:-str}"
    field_options="${parts[2]:-}"

    # 型マッピング
    case "$field_type" in
        str) col_type="String" ;;
        text) col_type="Text" ;;
        int) col_type="Integer" ;;
        float) col_type="Float" ;;
        bool) col_type="Boolean" ;;
        datetime) col_type="DateTime" ;;
        *) col_type="String" ;;
    esac

    # オプション処理
    nullable="False"
    unique=""
    index=""

    if [[ "$field_options" == *"optional"* ]]; then
        nullable="True"
    fi
    if [[ "$field_options" == *"unique"* ]]; then
        unique=", unique=True"
    fi
    if [[ "$field_options" == *"index"* ]]; then
        index=", index=True"
    fi

    echo "    ${field_name} = Column(${col_type}, nullable=${nullable}${unique}${index})" >> "app/models/${MODEL_LOWER}.py"
done

# タイムスタンプフィールド追加
cat >> "app/models/${MODEL_LOWER}.py" <<EOF
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
EOF

echo "✅ Generated: app/models/${MODEL_LOWER}.py"

# ======================================
# 2. スキーマ生成 (app/schemas/${MODEL_LOWER}/)
# ======================================

# base.py
cat > "app/schemas/${MODEL_LOWER}/base.py" <<EOF
"""${MODEL_CLASS} base schema."""
from pydantic import BaseModel, ConfigDict


class ${MODEL_CLASS}Base(BaseModel):
    """Base schema for ${MODEL_CLASS}."""
    model_config = ConfigDict(from_attributes=True)
EOF

for field_spec in "${FIELDS[@]}"; do
    IFS=':' read -ra parts <<< "$field_spec"
    field_name="${parts[0]}"
    field_type="${parts[1]:-str}"
    field_options="${parts[2]:-}"

    # Pydantic型マッピング
    case "$field_type" in
        str) py_type="str" ;;
        text) py_type="str" ;;
        int) py_type="int" ;;
        float) py_type="float" ;;
        bool) py_type="bool" ;;
        datetime) py_type="datetime" ;;
        *) py_type="str" ;;
    esac

    if [[ "$field_options" == *"optional"* ]]; then
        echo "    ${field_name}: ${py_type} | None = None" >> "app/schemas/${MODEL_LOWER}/base.py"
    else
        echo "    ${field_name}: ${py_type}" >> "app/schemas/${MODEL_LOWER}/base.py"
    fi
done

# create.py
cat > "app/schemas/${MODEL_LOWER}/create.py" <<EOF
"""${MODEL_CLASS} create schema."""
from app.schemas.${MODEL_LOWER}.base import ${MODEL_CLASS}Base


class ${MODEL_CLASS}Create(${MODEL_CLASS}Base):
    """Schema for creating ${MODEL_CLASS}."""
    pass
EOF

# update.py
cat > "app/schemas/${MODEL_LOWER}/update.py" <<EOF
"""${MODEL_CLASS} update schema."""
from pydantic import BaseModel


class ${MODEL_CLASS}Update(BaseModel):
    """Schema for updating ${MODEL_CLASS}."""
EOF

for field_spec in "${FIELDS[@]}"; do
    IFS=':' read -ra parts <<< "$field_spec"
    field_name="${parts[0]}"
    field_type="${parts[1]:-str}"

    case "$field_type" in
        str) py_type="str" ;;
        text) py_type="str" ;;
        int) py_type="int" ;;
        float) py_type="float" ;;
        bool) py_type="bool" ;;
        datetime) py_type="datetime" ;;
        *) py_type="str" ;;
    esac

    echo "    ${field_name}: ${py_type} | None = None" >> "app/schemas/${MODEL_LOWER}/update.py"
done

# response.py
cat > "app/schemas/${MODEL_LOWER}/response.py" <<EOF
"""${MODEL_CLASS} response schema."""
from datetime import datetime
from app.schemas.${MODEL_LOWER}.base import ${MODEL_CLASS}Base


class ${MODEL_CLASS}Response(${MODEL_CLASS}Base):
    """Schema for ${MODEL_CLASS} response."""
    id: int
    created_at: datetime
    updated_at: datetime
EOF

# __init__.py
cat > "app/schemas/${MODEL_LOWER}/__init__.py" <<EOF
"""${MODEL_CLASS} schemas."""
from app.schemas.${MODEL_LOWER}.base import ${MODEL_CLASS}Base
from app.schemas.${MODEL_LOWER}.create import ${MODEL_CLASS}Create
from app.schemas.${MODEL_LOWER}.response import ${MODEL_CLASS}Response
from app.schemas.${MODEL_LOWER}.update import ${MODEL_CLASS}Update

__all__ = [
    "${MODEL_CLASS}Base",
    "${MODEL_CLASS}Create",
    "${MODEL_CLASS}Response",
    "${MODEL_CLASS}Update",
]
EOF

echo "✅ Generated: app/schemas/${MODEL_LOWER}/"

# ======================================
# 3. リポジトリ生成 (app/db/repositories/${MODEL_LOWER}.py)
# ======================================
cat > "app/db/repositories/${MODEL_LOWER}.py" <<EOF
"""${MODEL_CLASS} repository."""
from app.db.repositories.base import BaseRepository
from app.models.${MODEL_LOWER} import ${MODEL_CLASS}


class ${MODEL_CLASS}Repository(BaseRepository[${MODEL_CLASS}]):
    """Repository for ${MODEL_CLASS} model."""

    pass
EOF

echo "✅ Generated: app/db/repositories/${MODEL_LOWER}.py"

# ======================================
# 4. エンドポイント生成 (app/api/v1/endpoints/${MODEL_PLURAL}.py)
# ======================================
cat > "app/api/v1/endpoints/${MODEL_PLURAL}.py" <<EOF
"""${MODEL_CLASS} endpoints."""
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.db.repositories.${MODEL_LOWER} import ${MODEL_CLASS}Repository
from app.schemas.${MODEL_LOWER} import ${MODEL_CLASS}Create, ${MODEL_CLASS}Response, ${MODEL_CLASS}Update

router = APIRouter()


@router.post("/", response_model=${MODEL_CLASS}Response, status_code=status.HTTP_201_CREATED)
async def create_${MODEL_LOWER}(
    ${MODEL_LOWER}_in: ${MODEL_CLASS}Create,
    db: AsyncSession = Depends(get_db),
) -> ${MODEL_CLASS}Response:
    """Create a new ${MODEL_LOWER}."""
    repository = ${MODEL_CLASS}Repository(db)
    ${MODEL_LOWER} = await repository.create(${MODEL_LOWER}_in.model_dump())
    return ${MODEL_CLASS}Response.model_validate(${MODEL_LOWER})


@router.get("/", response_model=List[${MODEL_CLASS}Response])
async def list_${MODEL_PLURAL}(
    skip: int = 0,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
) -> List[${MODEL_CLASS}Response]:
    """List ${MODEL_PLURAL} with pagination."""
    repository = ${MODEL_CLASS}Repository(db)
    ${MODEL_PLURAL} = await repository.get_all(skip=skip, limit=limit)
    return [${MODEL_CLASS}Response.model_validate(${MODEL_LOWER}) for ${MODEL_LOWER} in ${MODEL_PLURAL}]


@router.get("/{${MODEL_LOWER}_id}", response_model=${MODEL_CLASS}Response)
async def get_${MODEL_LOWER}(
    ${MODEL_LOWER}_id: int,
    db: AsyncSession = Depends(get_db),
) -> ${MODEL_CLASS}Response:
    """Get ${MODEL_LOWER} by ID."""
    repository = ${MODEL_CLASS}Repository(db)
    ${MODEL_LOWER} = await repository.get_by_id(${MODEL_LOWER}_id)
    if not ${MODEL_LOWER}:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="${MODEL_CLASS} not found")
    return ${MODEL_CLASS}Response.model_validate(${MODEL_LOWER})


@router.patch("/{${MODEL_LOWER}_id}", response_model=${MODEL_CLASS}Response)
async def update_${MODEL_LOWER}(
    ${MODEL_LOWER}_id: int,
    ${MODEL_LOWER}_in: ${MODEL_CLASS}Update,
    db: AsyncSession = Depends(get_db),
) -> ${MODEL_CLASS}Response:
    """Update ${MODEL_LOWER}."""
    repository = ${MODEL_CLASS}Repository(db)
    ${MODEL_LOWER} = await repository.update_by_id(${MODEL_LOWER}_id, ${MODEL_LOWER}_in.model_dump(exclude_unset=True))
    if not ${MODEL_LOWER}:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="${MODEL_CLASS} not found")
    return ${MODEL_CLASS}Response.model_validate(${MODEL_LOWER})


@router.delete("/{${MODEL_LOWER}_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_${MODEL_LOWER}(
    ${MODEL_LOWER}_id: int,
    db: AsyncSession = Depends(get_db),
) -> None:
    """Delete ${MODEL_LOWER}."""
    repository = ${MODEL_CLASS}Repository(db)
    deleted = await repository.delete_by_id(${MODEL_LOWER}_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="${MODEL_CLASS} not found")
EOF

echo "✅ Generated: app/api/v1/endpoints/${MODEL_PLURAL}.py"

# ======================================
# 5. テスト生成 (tests/test_api/test_${MODEL_PLURAL}.py)
# ======================================
cat > "tests/test_api/test_${MODEL_PLURAL}.py" <<EOF
"""Tests for ${MODEL_CLASS} endpoints."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_${MODEL_LOWER}(client: AsyncClient):
    """Test creating a ${MODEL_LOWER}."""
    data = {
EOF

# テストデータを生成
for field_spec in "${FIELDS[@]}"; do
    IFS=':' read -ra parts <<< "$field_spec"
    field_name="${parts[0]}"
    field_type="${parts[1]:-str}"
    field_options="${parts[2]:-}"

    # オプショナルフィールドはスキップ
    if [[ "$field_options" == *"optional"* ]]; then
        continue
    fi

    # 型に応じたテストデータ
    case "$field_type" in
        str|text) test_value="\"test ${field_name}\"" ;;
        int) test_value="1" ;;
        float) test_value="1.0" ;;
        bool) test_value="true" ;;
        *) test_value="\"test ${field_name}\"" ;;
    esac

    echo "        \"${field_name}\": ${test_value}," >> "tests/test_api/test_${MODEL_PLURAL}.py"
done

cat >> "tests/test_api/test_${MODEL_PLURAL}.py" <<EOF
    }
    response = await client.post("/api/v1/${MODEL_PLURAL}/", json=data)
    assert response.status_code == 201
    assert response.json()["id"] is not None


@pytest.mark.asyncio
async def test_list_${MODEL_PLURAL}(client: AsyncClient):
    """Test listing ${MODEL_PLURAL}."""
    response = await client.get("/api/v1/${MODEL_PLURAL}/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.asyncio
async def test_get_${MODEL_LOWER}(client: AsyncClient):
    """Test getting a ${MODEL_LOWER}."""
    # Create first
    data = {
EOF

for field_spec in "${FIELDS[@]}"; do
    IFS=':' read -ra parts <<< "$field_spec"
    field_name="${parts[0]}"
    field_type="${parts[1]:-str}"
    field_options="${parts[2]:-}"

    if [[ "$field_options" == *"optional"* ]]; then
        continue
    fi

    case "$field_type" in
        str|text) test_value="\"test ${field_name}\"" ;;
        int) test_value="1" ;;
        float) test_value="1.0" ;;
        bool) test_value="true" ;;
        *) test_value="\"test ${field_name}\"" ;;
    esac

    echo "        \"${field_name}\": ${test_value}," >> "tests/test_api/test_${MODEL_PLURAL}.py"
done

cat >> "tests/test_api/test_${MODEL_PLURAL}.py" <<EOF
    }
    create_response = await client.post("/api/v1/${MODEL_PLURAL}/", json=data)
    ${MODEL_LOWER}_id = create_response.json()["id"]

    # Get
    response = await client.get(f"/api/v1/${MODEL_PLURAL}/{${MODEL_LOWER}_id}")
    assert response.status_code == 200
    assert response.json()["id"] == ${MODEL_LOWER}_id


@pytest.mark.asyncio
async def test_update_${MODEL_LOWER}(client: AsyncClient):
    """Test updating a ${MODEL_LOWER}."""
    # Create first
    data = {
EOF

for field_spec in "${FIELDS[@]}"; do
    IFS=':' read -ra parts <<< "$field_spec"
    field_name="${parts[0]}"
    field_type="${parts[1]:-str}"
    field_options="${parts[2]:-}"

    if [[ "$field_options" == *"optional"* ]]; then
        continue
    fi

    case "$field_type" in
        str|text) test_value="\"test ${field_name}\"" ;;
        int) test_value="1" ;;
        float) test_value="1.0" ;;
        bool) test_value="true" ;;
        *) test_value="\"test ${field_name}\"" ;;
    esac

    echo "        \"${field_name}\": ${test_value}," >> "tests/test_api/test_${MODEL_PLURAL}.py"
done

cat >> "tests/test_api/test_${MODEL_PLURAL}.py" <<EOF
    }
    create_response = await client.post("/api/v1/${MODEL_PLURAL}/", json=data)
    ${MODEL_LOWER}_id = create_response.json()["id"]

    # Update
    update_data = {"${FIELDS[0]%%:*}": "updated value"}
    response = await client.patch(f"/api/v1/${MODEL_PLURAL}/{${MODEL_LOWER}_id}", json=update_data)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_delete_${MODEL_LOWER}(client: AsyncClient):
    """Test deleting a ${MODEL_LOWER}."""
    # Create first
    data = {
EOF

for field_spec in "${FIELDS[@]}"; do
    IFS=':' read -ra parts <<< "$field_spec"
    field_name="${parts[0]}"
    field_type="${parts[1]:-str}"
    field_options="${parts[2]:-}"

    if [[ "$field_options" == *"optional"* ]]; then
        continue
    fi

    case "$field_type" in
        str|text) test_value="\"test ${field_name}\"" ;;
        int) test_value="1" ;;
        float) test_value="1.0" ;;
        bool) test_value="true" ;;
        *) test_value="\"test ${field_name}\"" ;;
    esac

    echo "        \"${field_name}\": ${test_value}," >> "tests/test_api/test_${MODEL_PLURAL}.py"
done

cat >> "tests/test_api/test_${MODEL_PLURAL}.py" <<EOF
    }
    create_response = await client.post("/api/v1/${MODEL_PLURAL}/", json=data)
    ${MODEL_LOWER}_id = create_response.json()["id"]

    # Delete
    response = await client.delete(f"/api/v1/${MODEL_PLURAL}/{${MODEL_LOWER}_id}")
    assert response.status_code == 204
EOF

echo "✅ Generated: tests/test_api/test_${MODEL_PLURAL}.py"

# ======================================
# 完了メッセージ
# ======================================
echo ""
echo "🎉 Scaffold generation complete!"
echo ""
echo "Next steps:"
echo "  1. Add router to app/api/v1/router.py:"
echo "     from app.api.v1.endpoints import ${MODEL_PLURAL}"
echo "     router.include_router(${MODEL_PLURAL}.router, prefix=\"/${MODEL_PLURAL}\", tags=[\"${MODEL_PLURAL}\"])"
echo ""
echo "  2. Import model in app/models/__init__.py:"
echo "     from app.models.${MODEL_LOWER} import ${MODEL_CLASS}"
echo ""
echo "  3. Run migration:"
echo "     alembic revision --autogenerate -m \"Add ${MODEL_PLURAL} table\""
echo "     alembic upgrade head"
echo ""
