# terratform

DeepLX Lambda proxy Terraform workspace.

## Layout

- `app/service`: FastAPI Lambda app
- `infra/modules/deeplx_proxy`: DeepLX Lambda proxy module
- `infra/envs/prod`: production root config
- `scripts/build-lambda.sh`: Lambda artifact builder
- `scripts/local-run.sh`: local app runner
- `docs/deeplx-lambda-proxy-apply-plan.md`: apply plan

## Build

```sh
bash scripts/build-lambda.sh
```

Artifacts:

- `dist/lambda-app.zip`
- `dist/lambda-layer.zip`

## Local Run

```sh
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
PYTHON_BIN=python3.13 bash scripts/local-run.sh
```

## Validate

Build artifacts first, then:

```sh
python3.13 -m compileall app
PYTHONPATH=app pytest -q
PYTHON_BIN=python3.13 bash scripts/build-lambda.sh
terraform fmt -check -recursive
terraform -chdir=infra/envs/prod init -backend=false
terraform -chdir=infra/envs/prod validate
```
