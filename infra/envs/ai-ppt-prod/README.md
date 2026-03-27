# ai-ppt prod

Lightsail 기반 `ai_ppt` 운영 환경.

## Flow

1. `terraform init`
2. `cp terraform.tfvars.example terraform.tfvars`
3. `key_pair_name` 등 값 입력
4. `terraform plan`
5. `terraform apply`
6. 생성된 Lightsail 인스턴스에 SSH 접속
7. `/opt/ai-ppt/deploy/lightsail/app.env` 값 채우기
8. `/opt/ai-ppt/deploy/lightsail/secrets/` 에 필요한 JSON 업로드
9. `/opt/ai-ppt/deploy/lightsail/deploy.sh`
