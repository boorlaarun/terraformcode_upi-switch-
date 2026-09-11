variable "aws_region" {
  description = "AWS region to deploy VPC-C and EKS into (us-east-1 has 6 AZs, enough for our 4 nodes)"
  type        = string
  default     = "us-east-1"
}

variable "vpc_c_cidr" {
  description = "CIDR block for VPC-C (App/EKS VPC)"
  type        = string
  default     = "10.30.0.0/16"
}

# 4 private subnets -> 1 per AZ -> 1 EKS node per subnet
variable "private_subnet_cidrs" {
  description = "Private subnets: index0=node1(AZ-A), index1=node2(AZ-B), index2=node3(AZ-C), index3=node4(AZ-D)"
  type        = list(string)
  default = [
    "10.30.1.0/24", # AZ-A -> node1
    "10.30.2.0/24", # AZ-B -> node2
    "10.30.3.0/24", # AZ-C -> node3
    "10.30.4.0/24", # AZ-D -> node4
  ]
}

variable "azs" {
  description = "4 Availability Zones, in order [AZ-A(node1), AZ-B(node2), AZ-C(node3), AZ-D(node4)]"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
}

variable "cluster_name" {
  description = "EKS cluster name for VPC-C"
  type        = string
  default     = "vpc-c-app-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS control plane"
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS managed node groups"
  type        = string
  default     = "t3.medium"
}

variable "ecr_repository_name" {
  description = "Name of the EXISTING private ECR repository that already has the custom nginx image pushed to it (update this to your real repo name)"
  type        = string
  default     = "nginx-custom"
}

variable "ecr_image_tag" {
  description = "Image tag to deploy from the existing ECR repository"
  type        = string
  default     = "latest"
}
