from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="BANK_", env_file=".env", extra="ignore")

    jwt_secret: str = Field(...)
    jwt_ttl_seconds: int = 3600
    db_url: str = "sqlite:///./abc_bank.db"

    smtp_host: str | None = None
    smtp_port: int = 587
    smtp_username: str | None = None
    smtp_password: str | None = None
    smtp_from: str | None = None

    @field_validator("jwt_secret")
    @classmethod
    def _check_secret_length(cls, v: str) -> str:
        if len(v.encode("utf-8")) < 32:
            raise ValueError("BANK_JWT_SECRET must be at least 32 bytes")
        return v


def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
