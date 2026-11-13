# PERN Store three-tier Terraform project

This folder contains a modular Terraform deployment for the PERN Store application across three AWS environments: development, staging, and production.

## Application architecture note

The application inspection confirmed the following:

- Frontend: Vite React app built as a static site and served on port 3000 in Docker
- Backend: Node.js + Express app running on port 9000 in Docker
- Frontend production API base URL is configured with `VITE_API_URL` and falls back to `http://localhost:9000/api` in local development
- The Express server mounts the API under `/api` and returns the root route `/`, but it does not currently have a dedicated `/health` endpoint
- The app has a public root route that responds with HTTP 200. A dedicated `/health` endpoint would be preferable for production monitoring.

This Terraform project therefore uses `/` for both frontend and backend health checks until the app exposes a dedicated health route.

## Directory structure

- `bootstrap/terraform-state` creates the shared remote state bucket
- `modules/` contains reusable networking, security-group, ECS, ALB, RDS, IAM, ECR, WAF, monitoring, and CloudFront modules
- `environments/dev`, `environments/staging`, and `environments/production` configure each environment independently

## Bootstrap and state

The bootstrap folder creates an S3 state bucket with a cryptographically random 32-character hexadecimal suffix, versioning, encryption, and secure-transport policy enforcement. The suffix uses only lowercase hexadecimal characters, so the generated name complies with S3 bucket naming rules. The environments are configured to use local state by default during the initial setup so the bucket can be created first.

After creating the bucket, copy the `bucket_name` output into the `bucket` field of the environment's `backend.hcl`. Each environment has a commented S3 backend block in `main.tf`; uncomment it to switch that environment from local state to S3. Then run this from that environment directory:

```powershell
terraform init -migrate-state -backend-config=backend.hcl
```

Terraform will migrate that environment's existing local state into the configured S3 bucket. Keep the backend block commented while bootstrapping the bucket itself; bootstrap uses local state.

## Deployment flow

1. `cd three-tier-terraform\bootstrap\terraform-state`
2. `terraform init`
3. `terraform plan`
4. `terraform apply`
5. Copy the bootstrap `bucket_name` output into the environment `backend.hcl` file(s)
6. `cd ..\..\environments\dev`
7. Build and push the required image tags to ECR before the environment apply. The backend image must include `scripts/migrate.js` and the `migrations/` directory.
8. `terraform init -backend=false`
9. `terraform plan`
10. `terraform apply`; Terraform runs the database migration as a one-off Fargate task before creating or updating the backend service.

## Manual Docker pushes

The project expects the user to build and push images manually to ECR after the bootstrap Terraform configuration creates the repositories.

Example PowerShell sequence:

```powershell
# Log in to ECR
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 438424052578.dkr.ecr.ap-southeast-2.amazonaws.com

# Build frontend image
docker build -t store/frontend:v2 .\client

docker tag store/frontend:v2 438424052578.dkr.ecr.ap-southeast-2.amazonaws.com/store/frontend:v2
docker push 438424052578.dkr.ecr.ap-southeast-2.amazonaws.com/store/frontend:v2

# Build backend image
docker build -t store/backend:latest .\server

docker tag store/backend:latest 438424052578.dkr.ecr.ap-southeast-2.amazonaws.com/store/backend:latest
docker push 438424052578.dkr.ecr.ap-southeast-2.amazonaws.com/store/backend:latest
```

## Notes

- No AWS resources are created during code generation.
- The project intentionally avoids hard-coded credentials and keeps secrets in AWS Secrets Manager.
- ECS services are disabled by default so infrastructure can be created before the first image push.
- The shared `store/frontend` and `store/backend` ECR repositories are existing account resources. Each environment looks them up and uses immutable image tags.
- App signing secrets use a generated name suffix, while ECS reads their ARN from Terraform. This avoids a name collision when a destroyed secret remains scheduled for deletion during a redeploy; the normal Secrets Manager recovery window is preserved.
- The frontend calls the backend through the same ALB using the relative `/api` path, so frontend builds do not depend on an ALB hostname that can change after redeployment.
- The backend service waits for a one-off ECS Fargate migration task to complete. Its image must contain the current migration script and migration files; Terraform uses the configured backend image tag for both the migration and service.
- The ALB is internet-facing in every environment and uses public subnets. Its security group permits HTTP and HTTPS from the internet; without a certificate, the HTTP listener serves the frontend and routes `/api/*` to the backend.
- After applying an environment, run `terraform output -raw alb_dns_name` from its directory and open `http://<alb-dns-name>` to access the application directly through the ALB. HTTPS is enabled only when `certificate_arn` is set.
- CloudFront and its WAF association are not included in the environment deployments for now. Their module source is retained for possible later use.
