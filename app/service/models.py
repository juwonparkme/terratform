from enum import Enum
from typing import Any

from pydantic import BaseModel, Field

JSONValue = dict[str, Any] | list[Any] | str | int | float | bool | None


class HttpMethod(str, Enum):
    GET = "GET"
    POST = "POST"
    PATCH = "PATCH"
    DELETE = "DELETE"
    PUT = "PUT"


class Commitment(BaseModel):
    unique_id: str
    headers: dict[str, str] = Field(default_factory=dict)
    body: JSONValue = None


class CommitmentResult(BaseModel):
    unique_id: str
    status_code: int
    response: JSONValue


class CommitRequest(BaseModel):
    url: str
    http_method: HttpMethod
    commitments: list[Commitment]
    timeout_secs: float = 30


class CommitResponse(BaseModel):
    responses: list[CommitmentResult]

