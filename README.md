# terratform

DeepLX Lambda proxy Terraform workspace.

## Layout

- `app/service`: FastAPI Lambda app
- `docs/aws-manual-inputs.md`: AWS에서 수동 준비할 값 정리
- `docs/deeplx-proxy-runbook.md`: 빌드, 배포, 검증, 삭제 전체 매뉴얼
- `docs/terraform-state-bucket-setup.md`: Terraform 전용 state bucket / lock table 생성 방법
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
