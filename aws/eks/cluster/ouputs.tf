output "endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "eks" {
  value = local.eks
}

output "default_eks" {
  value = local.default_eks
}

output "access_config" {
  value = local.eks.access_config
}