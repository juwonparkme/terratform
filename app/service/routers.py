import asyncio
from collections.abc import Callable

import aiohttp
from fastapi import APIRouter

from service.config import get_settings
from service.models import Commitment, CommitmentResult, CommitRequest, CommitResponse, HttpMethod

router = APIRouter()

_HTTP_METHOD_MAPPINGS: dict[HttpMethod, Callable[[aiohttp.ClientSession], Callable]] = {
    HttpMethod.GET: lambda session: session.get,
    HttpMethod.POST: lambda session: session.post,
    HttpMethod.DELETE: lambda session: session.delete,
    HttpMethod.PATCH: lambda session: session.patch,
    HttpMethod.PUT: lambda session: session.put,
}


def _get_method_func(http_method: HttpMethod, session: aiohttp.ClientSession) -> Callable:
    method_factory = _HTTP_METHOD_MAPPINGS.get(http_method)
    if method_factory is None:
        raise ValueError(f"Unsupported HTTP method: {http_method}")
    return method_factory(session)


async def _dispatch_request(
    session: aiohttp.ClientSession,
    base_url: str,
    http_method: HttpMethod,
    commitment: Commitment,
) -> CommitmentResult:
    request_kwargs: dict[str, object] = {
        "headers": commitment.headers,
    }
    if commitment.body is not None:
        request_kwargs["json"] = commitment.body

    try:
        method = _get_method_func(http_method, session)
        async with method(base_url, **request_kwargs) as response:
            content_type = response.headers.get("content-type", "")
            if "application/json" in content_type:
                payload = await response.json()
            else:
                payload = await response.text()
            return CommitmentResult(
                unique_id=commitment.unique_id,
                status_code=response.status,
                response=payload,
            )
    except asyncio.TimeoutError:
        return CommitmentResult(
            unique_id=commitment.unique_id,
            status_code=504,
            response="upstream request timed out",
        )
    except aiohttp.ClientError as exc:
        return CommitmentResult(
            unique_id=commitment.unique_id,
            status_code=502,
            response=str(exc),
        )
    except Exception as exc:
        return CommitmentResult(
            unique_id=commitment.unique_id,
            status_code=500,
            response=str(exc),
        )


@router.get("/health")
async def health_check() -> dict[str, object]:
    settings = get_settings()
    return {
        "status": "ok",
        "function_index": settings.function_index,
    }


@router.post("/commit", response_model=CommitResponse)
async def commit_request(request: CommitRequest) -> CommitResponse:
    timeout = aiohttp.ClientTimeout(total=request.timeout_secs)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        responses = await asyncio.gather(
            *[
                _dispatch_request(
                    session=session,
                    base_url=request.url,
                    http_method=request.http_method,
                    commitment=commitment,
                )
                for commitment in request.commitments
            ]
        )

    return CommitResponse(responses=responses)

