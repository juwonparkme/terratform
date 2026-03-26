# Terraform 전용 State Bucket 만드는 방법

이 문서는 `terratform`용 Terraform state backend를 위해, 전용 S3 bucket과 DynamoDB lock table을 AWS에서 직접 만드는 절차를 정리한다.

기준.

- 용도: Terraform state 전용
- 테스트 환경: HTTP only
- 원칙: 기존 static bucket 재사용 금지

## 1. 왜 전용 bucket을 따로 만들어야 하나

현재 확인한 static bucket.

- `juwon-quizai-static-455021421504`

이 버킷은 static asset / CloudFront 용도다.

재사용 비권장 이유.

- Terraform state와 static file 용도가 다름
- bucket policy가 이미 CloudFront read 기준으로 맞춰져 있음
- state 파일은 민감한 인프라 메타데이터라 전용 관리가 안전
- 나중에 lifecycle/policy/versioning 기준도 달라짐

권장 분리.

- state bucket: Terraform state 전용
- artifact bucket: Lambda zip 업로드용
- static bucket: 웹 정적 파일 전용

## 2. 이번 프로젝트에서 직접 만들어야 하는 것

### 2.1 S3 bucket 1개

용도.

- Terraform state 저장

예시 이름.

- `juwonparkme-terraform-state`
- `juwon-terraform-state-455021421504`

권장 규칙.

- 전역 유니크
- 전부 소문자
- 하이픈 사용
- 프로젝트명이 아니라 "공용 state 저장소" 느낌으로 이름 짓기

### 2.2 DynamoDB table 1개

용도.

- Terraform state lock

예시 이름.

- `terraform-locks`
- `juwon-terraform-locks`

필수 key schema.

- partition key: `LockID`
- type: `String`

## 3. 콘솔에서 만드는 방법

## 3.1 S3 state bucket 생성

AWS Console 경로.

- AWS Console
- S3
- `Create bucket`

입력 권장값.

- Bucket type: General purpose
- Bucket name: `juwonparkme-terraform-state` 같은 유니크 이름
- AWS Region: 배포할 리전과 맞추기
  - 예: `us-east-1`
- Object Ownership: 기본값 유지
- Block Public Access: 전부 켜둠
- Versioning: 켜기 권장
- Default encryption: 기본값 유지 또는 SSE-S3

메모.

- bucket 이름과 region은 생성 후 바꿀 수 없음
- state bucket은 public 열 이유 없음

## 3.2 DynamoDB lock table 생성

AWS Console 경로.

- AWS Console
- DynamoDB
- `Create table`

입력 권장값.

- Table name: `terraform-locks`
- Partition key: `LockID`
- Partition key type: `String`
- Table settings: 기본값 또는 on-demand

메모.

- 테스트/소규모면 on-demand가 가장 단순
- lock table은 데이터 저장용이 아니라 충돌 방지용

## 4. CLI로 만드는 방법

CLI도 가능하다. 실제 실행은 네가 직접 하면 된다.

### 4.1 S3 bucket 생성

`us-east-1` 예시.

```sh
aws s3api create-bucket \
  --bucket juwonparkme-terraform-state \
  --region us-east-1
```

주의.

- `us-east-1`은 `--create-bucket-configuration LocationConstraint=...` 없이 생성
- 다른 리전은 `LocationConstraint` 필요

버전 관리 켜기.

```sh
aws s3api put-bucket-versioning \
  --bucket juwonparkme-terraform-state \
  --versioning-configuration Status=Enabled
```

퍼블릭 액세스 차단.

```sh
aws s3api put-public-access-block \
  --bucket juwonparkme-terraform-state \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### 4.2 DynamoDB table 생성

```sh
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## 5. 만든 뒤 확인해야 하는 값

이 값들을 Terraform에 넣는다.

### 5.1 `backend.hcl`

```hcl
bucket         = "juwonparkme-terraform-state"
key            = "terratform/deeplx-proxy/prod.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
```

각 값 의미.

- `bucket`: 방금 만든 state bucket 이름
- `key`: bucket 내부 state 파일 경로
- `region`: bucket과 backend가 위치한 리전
- `dynamodb_table`: 방금 만든 lock table 이름

## 6. `key`는 어떻게 정하나

`key`는 AWS에서 생성하는 값이 아니다.

그냥 문자열 경로를 정하면 된다.

권장값.

- `terratform/deeplx-proxy/prod.tfstate`

규칙.

- 프로젝트/환경 단위로 구분
- 나중에 staging 추가 시 일관성 유지

예.

- `terratform/deeplx-proxy/prod.tfstate`
- `terratform/deeplx-proxy/staging.tfstate`
- `terratform/another-project/prod.tfstate`

## 7. 테스트용 최소 권장안

지금 상황에 가장 단순한 조합.

- state bucket: `juwonparkme-terraform-state`
- lock table: `terraform-locks`
- backend key: `terratform/deeplx-proxy/prod.tfstate`
- region: `us-east-1`

## 8. 생성 후 다음 단계

여기까지 준비되면 다음 파일만 채우면 된다.

- `infra/envs/prod/backend.hcl`
- `infra/envs/prod/terraform.tfvars`

그다음 순서.

1. `PYTHON_BIN=python3.13 bash scripts/build-lambda.sh`
2. `terraform -chdir=infra/envs/prod init -backend-config=backend.hcl`
3. `terraform -chdir=infra/envs/prod validate`
4. `terraform -chdir=infra/envs/prod plan`

여기서 `plan`까지만 보면 배포 직전 상태다.
