from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.db import init_db
from app.errors import register_handlers
from app.routers import accounts, auth, health, transactions


@asynccontextmanager
async def _lifespan(app: FastAPI) -> AsyncIterator[None]:
    init_db()
    yield


def create_app() -> FastAPI:
    app = FastAPI(title="abc_bank (Python port)", version="0.1.0", lifespan=_lifespan)
    register_handlers(app)
    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(accounts.router)
    app.include_router(transactions.router)
    return app


app = create_app()
