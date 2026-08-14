module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.0"

  name               = "todo-app-eks"
  kubernetes_version = "1.33"

  endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  addons = {
    vpc-cni = {
      before_compute = true
    }

    kube-proxy = {}

    coredns = {}
  }

  eks_managed_node_groups = {
    todo_nodes = {
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 2
      desired_size = 2

      capacity_type = "ON_DEMAND"
    }
  }

  tags = {
    Project     = "todo-app"
    Environment = "dev"
  }
}