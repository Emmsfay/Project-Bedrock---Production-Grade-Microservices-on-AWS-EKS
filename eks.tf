module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "project-bedrock-cluster"
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = true   # ← ADD HERE
  endpoint_private_access = true   # ← ADD HERE

  enable_cluster_creator_admin_permissions = true

  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_entries = {          # ← ADD THIS BLOCK
    dev_user = {
      principal_arn = aws_iam_user.dev_user.arn
      policy_associations = {
        view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["retail-app"]
          }
        }
      }
    }
  }

  addons = {
    vpc-cni    = { most_recent = true }
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    amazon-cloudwatch-observability = { most_recent = true }
  }

  security_group_additional_rules = {    # ← not cluster_security_group_additional_rules
  ingress_nodes_all = {
    description                = "Allow all node traffic into cluster SG"
    protocol                   = "-1"
    from_port                  = 0
    to_port                    = 0
    type                       = "ingress"
    source_node_security_group = true
  }
}

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3
    }
  }

  tags = {
    Project = "barakat-2025-capstone"
  }
}


# Get authentication info for the cluster
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token

  # Prevents provider from blocking terraform operations if cluster unreachable
  ignore_annotations = []
}
