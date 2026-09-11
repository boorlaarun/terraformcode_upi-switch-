# ---------------------------------------------------------------------------
# VPC-C : APP (EKS APPLICATION VPC)
# Fully private. No Internet Gateway / NAT Gateway (per diagram notes).
# All AWS service access happens over VPC Endpoints.
#
# Subnet -> Node mapping:
#   private[0] = AZ-A -> node1
#   private[1] = AZ-B -> node2
#   private[2] = AZ-C -> node3
#   private[3] = AZ-D -> node4
# ---------------------------------------------------------------------------

resource "aws_vpc" "vpc_c" {
  cidr_block           = var.vpc_c_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-c-app-eks-vpc"
  }
}

locals {
  node_numbers = ["node1", "node2", "node3", "node4"]
}

resource "aws_subnet" "private" {
  count             = 4
  vpc_id            = aws_vpc.vpc_c.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name                                         = "vpc-c-private-${local.node_numbers[count.index]}-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }
}

# Single route table, local traffic only (no IGW/NAT here).
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc_c.id

  tags = {
    Name = "vpc-c-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = 4
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security group for VPC interface endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-c-endpoints-sg"
  description = "Allow HTTPS from within VPC-C to interface endpoints"
  vpc_id      = aws_vpc.vpc_c.id

  ingress {
    description = "HTTPS from VPC-C CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_c_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-c-endpoints-sg"
  }
}

# S3 Gateway endpoint (needed for EKS node bootstrap / image layers)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc_c.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

# Interface endpoints required for a fully private EKS cluster
locals {
  interface_endpoint_services = [
    "ecr.api",
    "ecr.dkr",
    "sts",
    "ec2",
    "elasticloadbalancing",
    "logs",
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = toset(local.interface_endpoint_services)
  vpc_id              = aws_vpc.vpc_c.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
