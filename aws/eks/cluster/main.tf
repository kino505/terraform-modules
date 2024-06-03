resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = local.eks.version
  role_arn = aws_iam_role.this.arn
  enabled_cluster_log_types = local.eks.enabled_cluster_log_types

  vpc_config {
    endpoint_private_access = local.eks.endpoint_private_access
    endpoint_public_access  = local.eks.endpoint_public_access

    subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
  }

  dynamic "access_config" {
    for_each = try(local.eks.access_config,{})
    content {
        authentication_mode                         = access_config.value.authentication_mode
        bootstrap_cluster_creator_admin_permissions = access_config.value.bootstrap_cluster_creator_admin_permissions
    }
  }

  dynamic "encryption_config" {
    for_each = try(local.eks.encryption_config,{})
    content {
        provider { 
            key_arn = encryption_config.value.key_arn
        }
        resources = encryption_config.value.resources
    }
  }

  dynamic "kubernetes_network_config" {
    for_each = try(local.eks.kubernetes_network_config,{})
    content {
        service_ipv4_cidr = kubernetes_network_config.value.service_ipv4_cidr
        ip_family         = kubernetes_network_config.ip_family
    }
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.vpc_resource_controller,
  ]
}

