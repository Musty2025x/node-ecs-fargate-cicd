# Runbook

## Rolling back a bad deployment

ECS keeps prior task definition revisions, so a rollback doesn't require a
new build.

1. **Find the last good revision:**
   ```bash
   aws ecs list-task-definitions \
     --family-prefix node-ecs-demo \
     --sort DESC --max-items 5
   ```

2. **Point the service at it:**
   ```bash
   aws ecs update-service \
     --cluster node-ecs-demo-cluster \
     --service node-ecs-demo-service \
     --task-definition node-ecs-demo:<REVISION_NUMBER> \
     --force-new-deployment
   ```

3. **Watch it stabilize:**
   ```bash
   aws ecs wait services-stable \
     --cluster node-ecs-demo-cluster \
     --services node-ecs-demo-service
   ```
   The ALB health check on `/health` keeps unhealthy tasks out of rotation
   during the switch, so this is zero-downtime in the same way forward
   deploys are.

4. **Fix forward:** once main is patched, the next merge redeploys the
   corrected image and Terraform's `container_image` var brings the task
   definition back in sync — no drift between what's running and what's in
   state.

## Checking why a task failed health checks

```bash
# Find the stopped task and its reason
aws ecs list-tasks --cluster node-ecs-demo-cluster --desired-status STOPPED
aws ecs describe-tasks --cluster node-ecs-demo-cluster --tasks <TASK_ARN>

# Tail application logs
aws logs tail /ecs/node-ecs-demo --follow
```

Common causes: container crashes on startup (bad env var, missing
dependency), health check path misconfigured, or the task role lacking a
permission the app needs at runtime.

## Tearing the environment down

```bash
cd terraform
terraform destroy
```

This removes the ALB, NAT Gateway, ECS service/cluster, and VPC — the
ongoing-cost items. The ECR repository and its images are retained unless
you also remove the `aws_ecr_repository` resource, so you don't lose build
artifacts between demo sessions.
