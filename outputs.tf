output "vpc_id" {
  description = "VPC-C VPC ID"
  value       = aws_vpc.vpc_c.id
}

output "private_subnet_ids" {
  description = "VPC-C private subnet IDs: [node1, node2, node3, node4]"
  value       = aws_subnet.private[*].id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint (private)"
  value       = module.eks.cluster_endpoint
}

output "node_group_a_d" {
  description = "Node group serving node1 & node4 -> API-1 (Hi Arun Sai)"
  value       = module.eks.eks_managed_node_groups["node_group_a_d"].node_group_id
}

output "node_group_b_c" {
  description = "Node group serving node2 & node3 -> API-2 (Hello Arun Sai)"
  value       = module.eks.eks_managed_node_groups["node_group_b_c"].node_group_id
}

output "how_to_call_apis" {
  description = "Local commands to test both APIs after apply"
  value       = <<-EOT
    # 1) Update local kubeconfig
    aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.aws_region}

    # 2) Call API-1 (node1 + node4) -> expect: Hi Arun Sai
    kubectl port-forward svc/api-1-svc 8081:80
    curl http://localhost:8081/   (returns HTML page with "Hi Arun Sai")

    # 3) Call API-2 (node2 + node3) -> expect: Hello Arun Sai
    kubectl port-forward svc/api-2-svc 8082:80
    curl http://localhost:8082/   (returns HTML page with "Welcome Arun Sai")
  EOT
}
