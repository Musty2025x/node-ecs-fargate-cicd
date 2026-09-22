variable "project_name" {
  description = "Name prefix used for all resources"
  type        = string
  default     = "node-ecs-demo"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (ECS tasks)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "AZs to spread subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "container_port" {
  description = "Port the Node.js app listens on"
  type        = number
  default     = 3000
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory (MiB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of running tasks"
  type        = number
  default     = 2
}

variable "container_image" {
  description = "Full image URI (ECR repo:tag). Defaults to a public placeholder so the first bootstrap apply succeeds."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest" # populated at apply time via -var or workflow
}

variable "github_repo" {
  description = "GitHub repo in 'org/name' form, used to scope the OIDC trust policy"
  type        = string
  default     = "Musty2025x/node-ecs-fargate-cicd"
}
