locals {
  pool_id            = coalesce(var.pool_id, "${var.environment}-github-pool")
  service_account_id = coalesce(var.service_account_id, "${var.environment}-cicd-sa")
}

# 1. Workload Identity Pool
resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = local.pool_id
  display_name              = "GitHub Actions Pool (${var.environment})"
  description               = "Workload Identity Pool for GitHub Actions CI/CD workflows"
  project                   = var.project_id
  disabled                  = false
}

# 2. Workload Identity Pool Provider for GitHub OIDC
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC identity provider for GitHub Actions"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# 3. Dedicated CI/CD Service Account
resource "google_service_account" "cicd_sa" {
  account_id   = local.service_account_id
  display_name = "GitHub Actions CI/CD (${var.environment})"
  project      = var.project_id
  description  = "Service account assumed by GitHub Actions via Workload Identity Federation"
}

# 4. Workload Identity User IAM Binding on CI/CD Service Account
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.cicd_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.repository/${var.github_repo}"
}

# 5. Least-Privilege IAM Roles for Automated Deployment
resource "google_project_iam_member" "cicd_roles" {
  for_each = toset(var.cicd_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.cicd_sa.email}"
}
