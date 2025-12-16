"""Baseline migration - schema.sql already applied.

Revision ID: 0001_baseline
Revises:
Create Date: 2025-01-01

This migration represents the initial schema from databases/monolith/schema.sql
which was applied during database initialization via docker-entrypoint-initdb.d.
"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "0001_baseline"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Schema already exists from docker-entrypoint-initdb.d/schema.sql
    # This is a baseline migration - no operations needed
    #
    # To mark the database as having this migration applied without running it:
    # docker compose exec nelo-api alembic stamp 0001_baseline
    pass


def downgrade() -> None:
    # WARNING: This would drop all schemas - not recommended for production
    # Uncomment only if you really need to reset the database
    #
    # op.execute("DROP SCHEMA IF EXISTS notifications CASCADE")
    # op.execute("DROP SCHEMA IF EXISTS payments CASCADE")
    # op.execute("DROP SCHEMA IF EXISTS deliveries CASCADE")
    # op.execute("DROP SCHEMA IF EXISTS orders CASCADE")
    # op.execute("DROP SCHEMA IF EXISTS users CASCADE")
    # op.execute("DROP SCHEMA IF EXISTS auth CASCADE")
    pass
