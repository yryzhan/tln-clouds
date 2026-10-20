mock_provider "aws" {
  mock_data "aws_iam_policy_document" { defaults = { json = "{}" } }
  mock_data "aws_caller_identity" { defaults = { account_id = "123456789012", arn = "arn:aws:iam::123456789012:user/test" } }
  mock_data "aws_region" { defaults = { region = "eu-central-1", name = "eu-central-1" } }
  mock_data "aws_partition" { defaults = { partition = "aws", dns_suffix = "amazonaws.com" } }
  mock_data "aws_acm_certificate" { defaults = { arn = "arn:aws:acm:eu-central-1:123456789012:certificate/test" } }
  mock_data "aws_iam_openid_connect_provider" { defaults = { arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/TEST", url = "oidc.eks.eu-central-1.amazonaws.com/id/TEST" } }
  mock_data "aws_eks_cluster" { defaults = { endpoint = "https://example.eks.amazonaws.com", certificate_authority = [{ data = "dGVzdA==" }], identity = [{ oidc = [{ issuer = "https://oidc.eks.eu-central-1.amazonaws.com/id/TEST" }] }] } }
}
mock_provider "kubernetes" {}
mock_provider "helm" {}
mock_provider "postgresql" {}
mock_provider "time" {}
mock_provider "awscc" {}
mock_provider "random" {}
mock_provider "null" {}

override_module {
  target  = module.rds
  outputs = {}
}
override_module {
  target  = module.cognito_user_pool
  outputs = {}
}
override_module {
  target  = module.secondary_certificate
  outputs = { acm_certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/secondary" }
}
override_module {
  target  = module.lb_controller_irsa_role
  outputs = { iam_role_arn = "arn:aws:iam::123456789012:role/lbc", arn = "arn:aws:iam::123456789012:role/lbc" }
}

variables {
  org_id             = "o"
  project_id         = "p"
  group_id           = "g"
  env_id             = "e"
  domain_name        = "example.com"
  dns_records        = ""
  use_primary_domain = false
  api_base_url       = "https://api.example.com"
  databases          = {}
}

run "nginx_release_rolls_pods" {
  command = plan
  providers = {
    aws        = aws
    awscc      = awscc
    kubernetes = kubernetes
    helm       = helm
    postgresql = postgresql
    time       = time
    random     = random
    null       = null
  }
  assert {
    condition     = helm_release.nginx.recreate_pods == false
    error_message = "recreate_pods deletes every ingress-nginx pod at once on upgrade; let the Deployment roll them"
  }
  assert {
    condition     = helm_release.nginx.force_update == false
    error_message = "force_update recreates resources on upgrade"
  }
}
