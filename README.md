VPC-C – Key Points
All subnets in VPC-C are private for secure application hosting.
Amazon ECR is used for container images. Since the EKS subnets are private, images are pulled through VPC endpoints without requiring direct Internet access.
Pod scheduling is configured with required node affinity and anti-affinity to ensure pods are distributed across the designated node groups for high availability.
US-East is used because the design requires multiple Availability Zones, providing better fault tolerance and high availability.
Traffic Flow:
External traffic → VPC → NACL → Private Subnet → Security Group → EC2/EKS workload → API response: “Hi Arun Sai”.
