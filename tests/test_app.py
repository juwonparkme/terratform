from fastapi.testclient import TestClient

from service import routers
from service.main import app
from service.models import CommitmentResult

client = TestClient(app)


def test_health_endpoint_exposes_function_index() -> None:
    response = client.get("/v0/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "function_index": 0,
    }


def test_commit_endpoint_aggregates_results(monkeypatch) -> None:
    async def fake_dispatch_request(session, base_url, http_method, commitment):
        return CommitmentResult(
            unique_id=commitment.unique_id,
            status_code=200,
            response={"echo": commitment.body},
        )

    monkeypatch.setattr(routers, "_dispatch_request", fake_dispatch_request)

    response = client.post(
        "/v0/commit",
        json={
            "url": "https://example.com/translate",
            "http_method": "POST",
            "timeout_secs": 5,
            "commitments": [
                {
                    "unique_id": "1",
                    "headers": {"Content-Type": "application/json"},
                    "body": {"text": "hello"},
                }
            ],
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "responses": [
            {
                "unique_id": "1",
                "status_code": 200,
                "response": {"echo": {"text": "hello"}},
            }
        ]
    }
