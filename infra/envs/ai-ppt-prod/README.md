# ai-ppt prod

Lightsail 기반 `ai_ppt` 운영 환경.

이 env는 다음 웹앱 배포 때도 템플릿처럼 복제해서 재사용하는 기준본.

## Reuse

비슷한 웹앱을 추가할 때는 `envs/ai-ppt-prod` 를 복제해서 새 env 만들고 아래 값만 교체.

1. `project_name`
2. `repo_url`
3. `repo_branch`
4. `app_directory`
5. `domain_name`
6. `hosted_zone_id`
7. `bootstrap_post_clone_commands`

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
