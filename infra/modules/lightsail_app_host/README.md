# lightsail_app_host

재사용 가능한 Lightsail 웹앱 호스트 모듈.

## What it creates

- Lightsail instance
- optional static IP + attachment
- public ports
- optional Route53 A record

## Typical use

```hcl
module "web_app" {
  source = "../../modules/lightsail_app_host"

  name              = "my-app-prod"
  availability_zone = "us-east-1a"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = "micro_3_0"
  key_pair_name     = "my-keypair"
  public_ports = [
    { from_port = 22, to_port = 22, protocol = "tcp" },
    { from_port = 80, to_port = 80, protocol = "tcp" },
    { from_port = 443, to_port = 443, protocol = "tcp" },
  ]
  domain_name    = "app.example.com"
  hosted_zone_id = "Z123456789"
  user_data      = file("${path.module}/user-data.sh")
}
```

## Reuse pattern

새 프로젝트는 이 모듈을 그대로 두고, `envs/<app>-prod/` 만 새로 만들어서 아래만 바꾸면 됨.

- `project_name`
- `repo_url`
- `repo_branch`
- `app_directory`
- `domain_name`
- `hosted_zone_id`
- `bootstrap_post_clone_commands`

즉, 인스턴스/고정 IP/공개 포트/기본 DNS는 공용 모듈에서 유지하고, 앱별 부트스트랩만 env 레벨에서 갈아끼우는 방식.
