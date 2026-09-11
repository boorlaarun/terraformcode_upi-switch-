# ---------------------------------------------------------------------------
# EKS cluster for VPC-C
#
# 2 Node Groups (for resilience — each group spans 2 AZs, so if one AZ/node
# goes down, the other node in the same group keeps serving traffic):
#
#   node_group_a_d -> node1 (AZ-A) + node4 (AZ-D)  -> runs API-1
#   node_group_b_c -> node2 (AZ-B) + node3 (AZ-C)  -> runs API-2
# ---------------------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = aws_vpc.vpc_c.id
  subnet_ids = aws_subnet.private[*].id

  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  enable_irsa = true

  eks_managed_node_group_defaults = {
    instance_types = [var.node_instance_type]
    ami_type       = "AL2023_x86_64_STANDARD"
  }

  eks_managed_node_groups = {

    # node1 (AZ-A) + node4 (AZ-D)
    node_group_a_d = {
      min_size     = 2
      max_size     = 2
      desired_size = 2

      subnet_ids = [
        aws_subnet.private[0].id, # node1 - AZ-A
        aws_subnet.private[3].id, # node4 - AZ-D
      ]

      # Real, meaningful label used later by Kubernetes nodeSelector
      labels = {
        "node-group" = "a-d"
      }

      tags = {
        Name = "vpc-c-node-group-a-d"
      }
    }

    # node2 (AZ-B) + node3 (AZ-C)
    node_group_b_c = {
      min_size     = 2
      max_size     = 2
      desired_size = 2

      subnet_ids = [
        aws_subnet.private[1].id, # node2 - AZ-B
        aws_subnet.private[2].id, # node3 - AZ-C
      ]

      labels = {
        "node-group" = "b-c"
      }

      tags = {
        Name = "vpc-c-node-group-b-c"
      }
    }
  }

  tags = {
    Name = "vpc-c-app-eks"
  }
}
