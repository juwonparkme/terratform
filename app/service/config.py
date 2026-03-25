from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    function_index: int = Field(default=0, alias="FUNCTION_INDEX")
    request_timeout_secs: float = Field(default=30, alias="REQUEST_TIMEOUT_SECS")

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
        populate_by_name=True,
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()

