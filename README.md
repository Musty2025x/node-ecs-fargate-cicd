# Dockerize & Deploy a Node.js App to AWS ECS Fargate with GitHub Actions

[![CI/CD](https://github.com/Musty2025x/node-ecs-fargate-cicd/actions/workflows/deploy.yml/badge.svg)](https://github.com/Musty2025x/node-ecs-fargate-cicd/actions/workflows/deploy.yml)

A minimal Node.js/Express API, containerized and deployed to **AWS ECS Fargate**
behind an **Application Load Balancer**, with all infrastructure defined in
**Terraform** and a **GitHub Actions** pipeline that authenticates to AWS via
**OIDC** (no long-lived access keys).

This repo is intentionally light on application code — the point is to
demonstrate a production-style deployment pipeline: containerization,
infrastructure-as-code, zero-downtime rolling deploys, and secretless CI/CD.

## Architecture

```
                        GitHub Actions (OIDC, no static keys)
                                    │
                    ┌───────────────┴───────────────┐
                    │                                │
              build & push                     terraform apply
              image to ECR                      + ecs update-service
                    │                                │
                    ▼                                ▼
         ┌─────────────────┐              ┌────────────────────────┐
         │   Amazon ECR     │◄─────────────│   ECS Task Definition   │
         └─────────────────┘   pulls image └────────────────────────┘
                                                       │
                                 VPC (10.0.0.0/16)     │
                    ┌──────────────────────────────────┴─────────────┐
                    │  Public subnets (2 AZs)                         │
                    │  ┌────────────────────────┐                    │
  Internet ────────►│  │  Application Load       │                   │
                    │  │  Balancer (:80)         │                   │
                    │  └───────────┬────────────┘                    │
                    │              │ target group (/health)          │
                    │  Private subnets (2 AZs)                       │
                    │  ┌───────────▼────────────┐                    │
                    │  │  ECS Fargate tasks       │  → CloudWatch     │
                    │  │  (Node.js container)     │    Logs           │
                    │  └─────────────────────────┘                   │
                    │              via NAT Gateway → Internet         │
                    └─────────────────────────────────────────────────┘
```

## Why these choices

- **Fargate over EC2** — no cluster capacity to patch or size; you pay per
  task. For a low-traffic demo/portfolio service this is cheaper and far
  less operational overhead than managing EC2 instances.
- **OIDC over static AWS access keys** — GitHub Actions assumes a
  short-lived IAM role scoped to this repo via `sts:AssumeRoleWithWebIdentity`.
  Nothing to rotate, nothing to leak.
- **Terraform over console clicks** — the entire environment is
  reproducible and destroyable with `terraform apply` / `terraform destroy`,
  which matters both for cost control and for interview conversations about
  "how do you avoid config drift."
- **Rolling deploys, not blue/green** — `deployment_minimum_healthy_percent =
  100` / `maximum_percent = 200` keeps full capacity serving traffic while
  new tasks start, and the ALB health check on `/health` gates traffic to
  new tasks. Good enough for this workload; documented in the runbook if you
  need to roll back.

## Repo layout

```
app/                  Express app (server.js), Dockerfile, tests
terraform/            VPC, ECR, ALB, ECS cluster/service, IAM + GitHub OIDC role
.github/workflows/    CI (lint/test) → build & push → terraform plan (PRs) → apply + deploy (main)
docs/runbook.md       Rollback / troubleshooting procedure
```

## Pipeline stages

1. **test** — installs deps, runs `npm test` (every push and PR)
2. **build-and-push** — builds the multi-stage Docker image, pushes to ECR tagged with the commit SHA
3. **terraform-plan** — on pull requests only, runs `terraform plan` so reviewers see the infra diff before merge
4. **deploy** — on merge to `main`: `terraform apply` (rolls the new image URI into the task definition), forces a new ECS deployment, and waits for the service to stabilize

## Setup

1. **Bootstrap AWS access for GitHub Actions** (one-time, run locally with your own credentials):
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars   # fill in your values
   terraform init
   terraform apply
   ```
   Copy the `github_actions_role_arn` output.

2. **Add repo secrets** (Settings → Secrets and variables → Actions):
   - `AWS_ROLE_ARN` — the ARN from step 1

3. **Push to `main`** — the pipeline builds, provisions infra, and deploys automatically. The ALB URL is in the `alb_dns_name` Terraform output.

## Cost note

Running 24/7: ~2 Fargate tasks (0.25 vCPU/0.5GB) + 1 NAT Gateway + 1 ALB is
roughly **$45–60/month** in `us-east-1`, dominated by the NAT Gateway and ALB
hourly charges rather than compute. Run `terraform destroy` when you're not
actively demoing it — see [docs/runbook.md](docs/runbook.md).

## Rollback

See [docs/runbook.md](docs/runbook.md) for the rollback procedure.

## License

MIT
