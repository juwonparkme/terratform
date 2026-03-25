import mangum
import uvicorn
from fastapi import FastAPI

from service.config import get_settings
from service.routers import router

settings = get_settings()

app = FastAPI(
    title="DeepLX Lambda Proxy",
    version="0.1.0",
)
app.include_router(router, prefix=f"/v{settings.function_index}")

handler = mangum.Mangum(app)

if __name__ == "__main__":
    uvicorn.run("service.main:app", host="0.0.0.0", port=1188)

