# DeepLX Lambda Proxy 적용 계획서

## 1. 목표

- `OrigamiDream/deeplx-lambda-proxy`의 `infra` 구조를 `terratform`에 이식
- 1차 목표: Terraform으로 `ALB -> Lambda N개 -> DeepLX upstream fan-out` 배포 가능 상태 확보
- 2차 목표: 운영 최소요건 반영
  - 원격 state
  - HTTPS
  - artifact build 자동화
  - 검증/배포 흐름

현재 `/Users/bagjuwon/Projects/terratform`는 사실상 빈 저장소라서, 단순 복사보다 "초기 뼈대 + 필요한 부분만 이식"이 맞다.

## 2. 업스트림 구조 요약

업스트림 `infra`는 아래 리소스를 만든다.

- VPC
  - public/private subnet
  - NAT gateway 1개
- ALB
  - `/v0/*`, `/v1/*` ... path rule
  - target type = Lambda
- Lambda layer 1개
  - Python dependency zip
- Lambda function `N`개
  - `FUNCTION_INDEX` 환경변수 주입
- S3 bucket + object
  - Lambda zip artifact 저장

앱 동작은 아래 흐름.

1. 클라이언트가 `POST /v{index}/commit` 호출
2. ALB가 대응 Lambda로 전달
3. Lambda 내부 FastAPI가 `commitments[]`를 비동기 fan-out
4. upstream DeepLX endpoint 응답 취합 후 반환

## 3. 업스트림 그대로 가져오면 생기는 문제

### 3.1 비용/구성 불일치

- VPC, subnet, NAT를 생성하지만 Lambda `vpc_config`는 주석 처리 상태
- 즉, 현재 코드 기준이면 VPC/NAT 비용만 생기고 Lambda는 그 VPC를 실제로 안 쓴다
- AWS 문서상 VPC 연결 Lambda가 public internet outbound 하려면 private subnet + NAT 구성이 필요하다
  - 참고: [Enable internet access for VPC-connected Lambda functions](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc-internet.html)

### 3.2 공개 엔드포인트 운영 기준 미달

- listener가 HTTP 80만 있음
- ACM/TLS/custom domain 없음
- public ALB를 그대로 열면 남용 가능성 큼

### 3.3 배포 안정성 부족

- Terraform backend 없음
- S3 bucket 이름이 `var.name` 하나라 충돌 가능
  - S3 bucket name은 global namespace
  - 참고: [General purpose bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
- Lambda layer 이름에 파일 경로 문자열 `md5`를 써서, 파일 내용이 바뀌어도 이름이 안 바뀔 수 있음

### 3.4 보안/운영 디테일 부족

- Lambda security group ingress all-open
- 실제로 Lambda를 VPC에 안 넣으면 SG 자체가 불필요
- ALB health check는 Lambda invocation 과금 대상
  - 참고: [Use Lambda functions as targets of an Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/lambda-functions.html)
- state lock, CI plan, smoke test, rollback 기준 없음

### 3.5 빌드 스크립트 검증 필요

- `archive-lambda-deps.sh`는 `pip install` target 인자를 중복 지정
- 그대로 재사용보다 `scripts/build-lambda.sh`로 재작성 권장

## 4. 권장 적용 방향

핵심 원칙: "업스트림 동작은 유지, 운영 리스크 큰 부분만 즉시 수정".

### 4.1 1차 권장안

- `ALB + Lambda N개` 구조는 유지
  - 사용자 입장 endpoint 패턴 유지 쉬움
  - upstream과 diff 작음
- 기본 모드는 **Lambda non-VPC**
  - 이유: upstream DeepLX 호출만 필요하면 기본 Lambda 네트워크로 outbound 가능
  - NAT 비용 제거
  - 보안그룹/서브넷/VPC 복잡도 제거
- HTTPS + custom domain은 prod 기준 기본 포함
- Terraform root/env 분리
- artifact build 스크립트/CI 추가

### 4.2 VPC는 옵션화

아래 경우에만 VPC 모드 활성화.

- 고정 egress IP 필요
- 사설 리소스 접근 필요
- 조직 정책상 Lambda VPC 강제

그 외에는 VPC 비활성 기본값 권장.

## 5. `terratform` 대상 권장 디렉터리 구조

```text
docs/
  deeplx-lambda-proxy-apply-plan.md
infra/
  modules/
    deeplx_proxy/
  envs/
    prod/
    staging/
scripts/
  build-lambda.sh
app/
  service/
.github/workflows/
  terraform-plan.yml
  terraform-apply.yml
```

## 6. 구현 단계

### Phase 0. 결정사항 확정

필수 확인값.

- AWS account / region
- `lambda_size`
- custom domain 사용 여부
- Route53 zone 보유 여부
- 인증 방식
  - 없음
  - basic auth
  - shared secret header
  - CloudFront/WAF/IP allowlist
- VPC 필요 여부
- state backend 위치

산출물.

- `prod` 기준 변수표
- 보안 노출 범위 정의

### Phase 1. 저장소 부트스트랩

작업.

- `infra/modules/deeplx_proxy` 생성
- `infra/envs/prod` 생성
- provider/version/backend/provider alias 정리
- 공통 naming/tagging locals 도입

완료 기준.

- `terraform init` 가능
- `terraform validate` 통과

### Phase 2. Lambda 앱/패키징 정리

작업.

- upstream `service/` 코드 이식
- `scripts/build-lambda.sh` 작성
  - dependency layer zip
  - app zip
  - hash 기반 재배포 가능 상태
- 로컬 smoke 실행 경로 추가

권장 변경.

- Python runtime 최신 지원 버전 검토 후 결정
- dependency pin 유지
- health/commit endpoint 샘플 요청 추가

완료 기준.

- 로컬에서 zip 2종 생성
- `source_code_hash` 변경 반영 확인

### Phase 3. Terraform 모듈 구현

작업.

- ALB
  - Lambda target group `N`개
  - path rule `/v{index}/*`
- Lambda
  - function `N`개
  - `FUNCTION_INDEX` 주입
  - permission 제한
- S3 artifact bucket
  - globally unique naming
  - versioning/encryption 옵션
- outputs
  - ALB DNS
  - endpoint list

권장 변경.

- bucket name에 account/region/env/random suffix 포함
- layer 이름은 파일 내용 hash 기반
- ALB listener는 prod에서 443 기본, 80 -> 443 redirect

완료 기준.

- `terraform plan`에서 리소스 구조 기대대로 표시
- endpoint output 생성

### Phase 4. 운영 보강

작업.

- Terraform remote state 연결
- ACM certificate + Route53 record
- 로그 보존기간 설정
- CloudWatch alarm
  - Lambda error
  - Lambda duration
  - ALB 5xx

선택 작업.

- WAF
- auth header validation
- rate limit

완료 기준.

- public prod endpoint가 HTTPS로 동작
- 기본 모니터링 확보

### Phase 5. CI/CD

작업.

- GitHub Actions
  - `terraform fmt -check`
  - `terraform validate`
  - `terraform plan`
- 수동 승인 후 `apply`
- artifact build 재현성 검증

완료 기준.

- PR에서 plan 확인 가능
- main 배포 절차 문서화

### Phase 6. 검증/컷오버

작업.

- `/v{index}/health` 전체 확인
- `/v{index}/commit` 샘플 요청 확인
- 여러 endpoint 랜덤 호출 smoke
- 실패/timeout 시나리오 확인

완료 기준.

- 최소 1회 end-to-end 성공
- 장애 시 복구 절차 문서화

## 7. 권장 Terraform 변수 초안

```hcl
region
project_name
environment
lambda_size
lambda_runtime
artifact_bucket_name_prefix
artifact_app_zip_path
artifact_layer_zip_path
enable_vpc
vpc_id
private_subnet_ids
domain_name
hosted_zone_id
certificate_arn
enable_waf
tags
```

## 8. 바로 반영할 설계 결정

### 결정 1. VPC 기본 비활성

- 이유: upstream 목적상 outbound HTTP만 필요
- 효과: NAT 비용 제거, subnet/SG 제거, 배포 단순화

### 결정 2. ALB 유지

- 이유: upstream path routing 구조 그대로 이식 쉬움
- `/v{index}` endpoint 패턴 유지 가능

### 결정 3. prod는 HTTPS 기본

- 이유: public proxy를 HTTP only로 열 이유 없음

### 결정 4. env 분리

- 이유: 빈 저장소라 root flat 구조보다 초기부터 `modules/envs`가 낫다

## 9. 리스크와 대응

### 리스크 1. public abuse

- 대응: auth header, WAF, IP allowlist 중 최소 1개

### 리스크 2. NAT/ALB 비용 과다

- 대응: 기본 non-VPC
- 필요 시 API Gateway/Function URL 대안 재검토

### 리스크 3. S3 bucket name 충돌

- 대응: unique suffix 강제

### 리스크 4. Lambda cold start / timeout

- 대응: timeout 조정, lambda_size 조정, CloudWatch 관측

### 리스크 5. 업스트림 drift

- 대응: app/service만 참조, infra는 우리 구조로 재구성

## 10. 권장 일정

### Day 1

- 결정사항 확정
- 저장소 구조 생성
- Lambda build 스크립트 작성

### Day 2

- Terraform module 구현
- prod env wiring
- first `plan`

### Day 3

- HTTPS/domain/state/CI 추가
- smoke test
- 컷오버 준비

## 11. 최종 권고

가장 안전한 시작점은 아래다.

1. upstream 앱 로직만 가져오기
2. Terraform은 `terratform` 스타일로 새로 짜기
3. VPC는 빼고 시작
4. prod만 HTTPS + domain + remote state 포함
5. smoke/plan/apply 흐름까지 같이 만들기

이 방식이 "upstream 호환성"과 "운영 가능성" 균형이 가장 좋다.
