# DeepLX Proxy Runbook

이 문서는 이번 작업에서 실제로 수행한 흐름을 기준으로, `terratform`에서 DeepLX Lambda proxy를 배포하고 검증하고 삭제하는 방법을 한 번에 정리한 매뉴얼이다.

관련 파일:

- `infra/envs/prod/backend.hcl.example`
- `infra/envs/prod/terraform.tfvars.example`
- `scripts/build-lambda.sh`
- `tests/test_app.py`
- `infra/modules/deeplx_proxy/alb.tf`

## 목적

이 워크스페이스는 아래 흐름으로 동작한다.

1. FastAPI 앱을 Lambda zip으로 빌드
2. Terraform이 ALB + Lambda + Lambda layer + VPC + artifact bucket 생성
3. ALB 경로 `/v0/*`, `/v1/*` 로 각 Lambda에 라우팅
4. `/v0/commit`, `/v1/commit` 으로 upstream HTTP 요청 프록시

## 1. 사전 준비

필수 조건:

- AWS CLI 인증 완료
- Terraform 설치
- 로컬 Python `3.13` 사용 권장

주의:

- 이 머신 기본 `python3` 가 `3.14` 인 경우 `pydantic-core` wheel 이슈가 있을 수 있다.
- 로컬 검증/빌드는 `python3.13` 기준으로 맞췄다.

확인 명령:

```sh
aws sts get-caller-identity
terraform version
python3.13 --version
```

## 2. Terraform backend 준비

Terraform state 저장용 S3 bucket, lock 용 DynamoDB table 이 먼저 필요하다.

예시:

```hcl
# infra/envs/prod/backend.hcl
bucket         = "juwon-terraform-state-455021421504"
key            = "terratform/deeplx-proxy/prod.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
```

각 값 의미:

- `bucket`: Terraform state 저장용 S3 bucket
- `key`: bucket 안 state 파일 경로
- `region`: backend 리전
- `dynamodb_table`: state lock table

상세 준비 방법:

- `docs/terraform-state-bucket-setup.md`
- `docs/aws-manual-inputs.md`

## 3. 배포 변수 준비

실제 인프라 값은 `terraform.tfvars` 에 넣는다.

HTTP 테스트용 최소 예시:

```hcl
project_name = "deeplx-proxy"
environment  = "prod"
aws_region   = "us-east-1"
lambda_size  = 2

lambda_runtime        = "python3.12"
lambda_handler        = "service/main.handler"
lambda_architectures  = ["x86_64"]
lambda_memory_size    = 256
lambda_timeout        = 300
log_retention_in_days = 14

lambda_app_archive_path   = "../../../dist/lambda-app.zip"
lambda_layer_archive_path = "../../../dist/lambda-layer.zip"
lambda_app_s3_key         = "apps/lambda-app.zip"
artifact_bucket_name      = "juwon-deeplx-proxy-artifacts-455021421504"

artifact_bucket_force_destroy = false
create_vpc                    = true
enable_vpc                    = false

availability_zones   = ["us-east-1a", "us-east-1b"]
vpc_cidr             = "10.30.0.0/16"
public_subnet_cidrs  = ["10.30.10.0/24", "10.30.11.0/24"]
private_subnet_cidrs = ["10.30.1.0/24", "10.30.2.0/24"]

vpc_id             = null
public_subnet_ids  = []
private_subnet_ids = []

certificate_arn         = null
domain_name             = null
hosted_zone_id          = null
alb_deletion_protection = false

environment_variables = {}

tags = {
  Owner = "Juwon Park"
}
```

역할:

- `backend.hcl`: Terraform state 저장 위치
- `terraform.tfvars`: 실제 AWS 리소스 구성값

둘 다 로컬 전용 파일로 관리:

- `infra/envs/prod/backend.hcl`
- `infra/envs/prod/terraform.tfvars`

현재 `.gitignore` 에 포함되어 있다.

## 4. 빌드

Lambda artifact 생성:

```sh
PYTHON_BIN=python3.13 bash scripts/build-lambda.sh
```

생성물:

- `dist/lambda-app.zip`
- `dist/lambda-layer.zip`

스크립트 역할:

- `app/service` 코드를 앱 zip 으로 패키징
- `requirements.txt` 의 의존성을 Lambda layer zip 으로 패키징

## 5. 테스트

로컬 최소 검증:

```sh
source .venv313/bin/activate
PYTHONPATH=app pytest -q
```

이 테스트는 최소 두 가지를 본다.

- `/v0/health` 가 function index 를 노출하는지
- `/v0/commit` 이 commitments 응답을 집계하는지

## 6. Terraform 초기화 / 검증 / 계획

```sh
terraform -chdir=infra/envs/prod init -backend-config=backend.hcl
terraform -chdir=infra/envs/prod validate
terraform -chdir=infra/envs/prod plan
```

각 단계:

- `init`: provider 다운로드, backend 연결
- `validate`: Terraform 문법/참조 검증
- `plan`: 실제 생성/변경/삭제 예정 리소스 미리보기

## 7. 배포

```sh
terraform -chdir=infra/envs/prod apply -auto-approve
```

이번 테스트 배포에서 실제 생성된 구성:

- ALB 1개
- Lambda 2개
- Lambda layer 1개
- artifact S3 bucket 1개
- CloudWatch log group 2개
- VPC / subnet / IGW / route table

생성 후 출력 예시:

```txt
alb_dns_name = "deeplx-proxy-prod-alb-456802047.us-east-1.elb.amazonaws.com"
base_url = "http://deeplx-proxy-prod-alb-456802047.us-east-1.elb.amazonaws.com"
proxy_commit_urls = [
  "http://deeplx-proxy-prod-alb-456802047.us-east-1.elb.amazonaws.com/v0/commit",
  "http://deeplx-proxy-prod-alb-456802047.us-east-1.elb.amazonaws.com/v1/commit",
]
```

## 8. 동작 확인

health check:

```sh
curl http://deeplx-proxy-prod-alb-456802047.us-east-1.elb.amazonaws.com/v0/health
curl http://deeplx-proxy-prod-alb-456802047.us-east-1.elb.amazonaws.com/v1/health
```

정상 응답:

```json
{"status":"ok","function_index":0}
{"status":"ok","function_index":1}
```

프록시 요청 테스트:

```sh
curl -X POST "http://deeplx-proxy-prod-alb-456802047.us-east-1.elb.amazonaws.com/v0/commit" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://api.deeplx.org/translate",
    "http_method": "POST",
    "timeout_secs": 5,
    "commitments": [
      {
        "unique_id": "1",
        "headers": { "Content-Type": "application/json" },
        "body": {
          "text": "Hello World!",
          "source_lang": "EN",
          "target_lang": "KO"
        }
      }
    ]
  }'
```

이번 실제 응답:

```json
{"responses":[{"unique_id":"1","status_code":200,"response":{"code":200,"id":1662450002,"data":"https://linux.do/t/topic/111737","alternatives":[]}}]}
```

의미:

- ALB -> Lambda -> upstream 호출 경로는 정상
- 다만 upstream 응답 내용은 대상 서비스 상태에 따라 기대와 다를 수 있다

추가 확인:

```sh
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region us-east-1
```

CloudWatch Logs:

- `/aws/lambda/deeplx-proxy-prod-0`
- `/aws/lambda/deeplx-proxy-prod-1`

## 9. 이번에 수정한 배포 이슈

배포 중 실제로 걸렸던 문제:

- Lambda target group health check 설정이 AWS 제약에 맞지 않아 target group 생성 실패

에러:

```txt
ValidationError: Health check interval must be greater than the timeout.
```

수정 파일:

- `infra/modules/deeplx_proxy/alb.tf`

반영 내용:

- `interval = 35`
- `timeout = 30`

참고:

- provider 가 Lambda target group 에서 `health_check.protocol` 경고를 여전히 출력할 수 있다.
- 현재는 apply 는 성공하지만, provider 업그레이드 시 이 블록은 다시 점검 필요.

## 10. 삭제

Terraform 관리 리소스 삭제:

```sh
terraform -chdir=infra/envs/prod destroy -auto-approve
```

이번 삭제 결과:

```txt
Destroy complete! Resources: 34 destroyed.
```

이후 수동 정리한 항목:

- Terraform state bucket 삭제
- DynamoDB lock table 삭제
- 작업 중 임시로 붙였던 IAM 권한 회수

검증 예:

```sh
terraform -chdir=infra/envs/prod state list
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[?contains(LoadBalancerName, `deeplx-proxy-prod`)].LoadBalancerName'
aws lambda list-functions --region us-east-1 --query 'Functions[?starts_with(FunctionName, `deeplx-proxy-prod`)].FunctionName'
```

정상 정리 상태:

- Terraform state 비어 있음
- `deeplx-proxy-prod*` ALB 없음
- `deeplx-proxy-prod*` Lambda 없음
- artifact bucket 없음
- backend bucket 없음
- lock table 없음

## 11. IAM 권한 메모

이번 테스트 중 임시로 넓게 붙였던 권한:

- `AmazonS3FullAccess`
- `AWSLambda_FullAccess`
- `AmazonVPCFullAccess`
- `CloudWatchLogsFullAccess`
- `AmazonDynamoDBFullAccess`
- inline policy `TerraformBackendBootstrap`

작업 종료 후 모두 제거했다.

남겨둔 기존 권한:

- `IAMFullAccess`
- `AmazonECS_FullAccess`
- `ElasticLoadBalancingFullAccess`

운영 재배포 전에는 최소 권한 정책으로 다시 정리하는 것이 맞다.
