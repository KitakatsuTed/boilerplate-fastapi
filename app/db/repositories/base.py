"""Base repository for CRUD operations."""

from typing import Dict, Generic, List, Type, TypeVar

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """Base repository with generic CRUD operations."""

    def __init__(self, db: AsyncSession, model: Type[ModelType] | None = None):
        """Initialize repository."""
        self.db = db
        # Genericの型パラメータからモデルクラスを取得
        if model is None:
            # サブクラスで __orig_bases__ から型を抽出
            orig_bases = getattr(self.__class__, "__orig_bases__", ())
            if orig_bases:
                # BaseRepository[ModelType] から ModelType を取得
                import typing

                if hasattr(typing, "get_args"):
                    args = typing.get_args(orig_bases[0])
                    if args:
                        model = args[0]
        self.model = model

    async def get_by_id(self, id: int) -> ModelType | None:
        """Get a record by ID."""
        result = await self.db.execute(select(self.model).where(self.model.id == id))
        return result.scalar_one_or_none()

    async def get_all(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """Get all records with pagination."""
        result = await self.db.execute(select(self.model).offset(skip).limit(limit))
        return list(result.scalars().all())

    async def get_where(self, **filters) -> List[ModelType]:
        """Get records by filters."""
        query = select(self.model)
        for key, value in filters.items():
            query = query.where(getattr(self.model, key) == value)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def create(self, obj_in: Dict) -> ModelType:
        """Create a new record."""
        db_obj = self.model(**obj_in)
        self.db.add(db_obj)
        await self.db.commit()
        await self.db.refresh(db_obj)
        return db_obj

    async def update_by_id(self, id: int, obj_in: Dict) -> ModelType | None:
        """Update a record by ID."""
        db_obj = await self.get_by_id(id)
        if not db_obj:
            return None

        for key, value in obj_in.items():
            if hasattr(db_obj, key):
                setattr(db_obj, key, value)

        self.db.add(db_obj)
        await self.db.commit()
        await self.db.refresh(db_obj)
        return db_obj

    async def delete_by_id(self, id: int) -> bool:
        """Delete a record by ID."""
        db_obj = await self.get_by_id(id)
        if not db_obj:
            return False

        await self.db.delete(db_obj)
        await self.db.commit()
        return True

    async def exists(self, **filters) -> bool:
        """Check if a record exists."""
        query = select(self.model)
        for key, value in filters.items():
            query = query.where(getattr(self.model, key) == value)
        result = await self.db.execute(query)
        return result.scalar_one_or_none() is not None

    async def count(self, **filters) -> int:
        """Count records."""
        from sqlalchemy import func

        query = select(func.count()).select_from(self.model)
        for key, value in filters.items():
            query = query.where(getattr(self.model, key) == value)
        result = await self.db.execute(query)
        return result.scalar_one()
