# AWS 수동 준비값 정리

이 문서는 `terratform` 코드를 실제 배포하기 전에, Juwon이 AWS에서 직접 준비하거나 확인해서 입력해야 하는 값만 정리한다.

Terraform state bucket 생성 절차는 별도 문서 참고.

- [docs/terraform-state-bucket-setup.md](/Users/bagjuwon/Projects/terratform/docs/terraform-state-bucket-setup.md)

범위.

- 포함: AWS 콘솔/CLI에서 직접 만들어야 하거나, 기존 자원에서 확인해야 하는 값
- 제외: Terraform이 스스로 생성하는 자원

## 1. 필수: Terraform backend

이건 Terraform 실행 전에 먼저 있어야 한다.

대상 파일.

- `infra/envs/prod/backend.hcl`

직접 준비할 것.

### 1.1 S3 state bucket

직접 AWS에서 만들 자원.

- S3 bucket 1개

입력할 값.

- `bucket`
  - 예: `juwonparkme-terraform-state`
- `region`
  - 예: `us-east-1`

설명.

- Terraform state 파일 저장 위치
- 이 bucket은 Terraform 코드가 아니라, Terraform 자신을 위해 먼저 있어야 함

### 1.2 DynamoDB lock table

직접 AWS에서 만들 자원.

- DynamoDB table 1개

입력할 값.

- `dynamodb_table`
  - 예: `terraform-locks`

권장 스펙.

- partition key: `LockID` (String)

설명.

- 동시 실행 lock 용도
- 여러 기기/사람이 Terraform 돌릴 때 state 충돌 방지

### 1.3 State file key

직접 정할 값.

- `key`
  - 예: `terratform/deeplx-proxy/prod.tfstate`

설명.

- S3 bucket 안의 state 파일 경로
- AWS에서 미리 만들 필요는 없음
- 문자열만 정하면 됨

## 2. 선택: HTTPS + custom domain

HTTP only면 이 섹션은 필요 없다.

대상 파일.

- `infra/envs/prod/terraform.tfvars`

직접 준비할 것.

### 2.1 ACM certificate

직접 AWS에서 만들 자원.

- ACM certificate 1개

입력할 값.

- `certificate_arn`

설명.

- ALB HTTPS listener에 연결
- `aws_region`과 같은 리전에 있어야 함

### 2.2 Route53 hosted zone

직접 AWS에서 만들거나, 기존 zone 확인.

- Route53 hosted zone 1개

입력할 값.

- `hosted_zone_id`
- `domain_name`
  - 예: `deeplx.example.com`

설명.

- Terraform은 record는 만들 수 있음
- 하지만 hosted zone 자체는 현재 코드에서 만들지 않음

## 3. 선택: 기존 네트워크 재사용

현재 기본값은 `create_vpc = true` 라서 이 섹션은 기본적으로 필요 없다.

필요한 경우.

- 기존 VPC를 재사용하고 싶을 때
- 보안/네트워크 정책 때문에 새 VPC 생성이 불가할 때

대상 파일.

- `infra/envs/prod/terraform.tfvars`

직접 확인할 값.

- `create_vpc = false`
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`

설명.

- `enable_vpc = false`면 `public_subnet_ids`만 필수
- `enable_vpc = true`면 `private_subnet_ids`도 필수

## 4. 사람이 직접 정해야 하는 운영값

AWS에서 "생성"하는 값은 아닐 수 있지만, 배포 전에 사람이 확정해야 한다.

대상 파일.

- `infra/envs/prod/terraform.tfvars`

직접 정할 값.

- `aws_region`
- `availability_zones`
- `lambda_size`
- `artifact_bucket_name`
- `environment_variables`

설명.

- `artifact_bucket_name`은 Terraform이 생성하지만, 버킷 이름은 사람이 먼저 정해야 함
- S3 bucket name은 전역 유니크여야 함

## 5. 현재 코드에서 Terraform이 생성하는 자원

이건 수동 생성 불필요.

- artifact S3 bucket
- Lambda layer
- Lambda functions
- CloudWatch log groups
- ALB
- ALB target groups / listeners / rules
- optional Route53 record
- optional VPC / subnet / NAT / security groups

## 6. 실제 입력 위치

### 6.1 `backend.hcl`

직접 채울 값.

```hcl
bucket         = "REPLACE_ME"
key            = "terratform/deeplx-proxy/prod.tfstate"
region         = "us-east-1"
dynamodb_table = "REPLACE_ME"
encrypt        = true
```

### 6.2 `terraform.tfvars`

필요한 경우만 채울 값.

```hcl
aws_region      = "us-east-1"
artifact_bucket_name = "REPLACE_ME_UNIQUE_BUCKET"

certificate_arn = null
domain_name     = null
hosted_zone_id  = null

create_vpc      = true
enable_vpc      = false

vpc_id             = null
public_subnet_ids  = []
private_subnet_ids = []
```

## 7. 최소 체크리스트

HTTP only / 새 VPC 생성 기준 최소 준비값.

1. state bucket 이름
2. state bucket region
3. DynamoDB lock table 이름
4. backend key 문자열
5. 배포 region
6. AZ 2개
7. artifact bucket 이름
8. lambda 개수

HTTPS + domain까지 쓰면 추가 준비값.

1. ACM certificate ARN
2. Route53 hosted zone id
3. domain name
