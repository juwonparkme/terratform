# Quiz_Ai prod

Minimal-cost Lightsail environment for `Quiz_Ai`.

This creates one Lightsail instance, one static IP, public ports for SSH/HTTP/HTTPS, and optionally one Route53 A record.

## Flow

1. `cp terraform.tfvars.example terraform.tfvars`
2. Set `key_pair_name`.
3. Set `hosted_zone_id` if Route53 should manage `quiz.juwonpark.me`.
4. For S3 state, copy `backend.tf.example` to `backend.tf` and set `backend.hcl`.
5. `terraform init`
6. `terraform plan`
7. `terraform apply`

The first boot installs Nginx, MySQL, Python dependencies, creates local app secrets in `/opt/quiz-ai/.env`, and starts `quiz-ai.service`.

## After apply

- Fill real app secrets in `/opt/quiz-ai/.env`, including `OPENAI_API_KEY`, OAuth, and email credentials.
- Restart with `sudo systemctl restart quiz-ai`.
- Issue HTTPS cert after DNS points at the static IP: `sudo apt-get install -y certbot python3-certbot-nginx && sudo certbot --nginx -d quiz.juwonpark.me`.
