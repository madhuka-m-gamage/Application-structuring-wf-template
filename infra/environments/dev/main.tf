terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Optional GCS backend configuration:
  # backend "gcs" {
  #   bucket = "YOUR_GCS_TFSTATE_BUCKET"
  #   prefix = "terraform/state/dev"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  environment            = "dev"
  tasks_topic_name       = "${local.environment}-tasks"
  task_events_topic_name = "${local.environment}-task-events"
  dead_letter_topic_name = "${local.environment}-dead-letter-topic"
}

# 1. Custom VPC, Private IP Allocation & Serverless VPC Access Connector
module "vpc" {
  source         = "../../modules/vpc"
  project_id     = var.project_id
  region         = var.region
  environment    = local.environment
  subnet_cidr    = var.subnet_cidr
  connector_cidr = var.connector_cidr
}

# 2. Artifact Registry for Container Images
module "artifact_registry" {
  source         = "../../modules/artifact_registry"
  project_id     = var.project_id
  region         = var.region
  environment    = local.environment
  immutable_tags = var.immutable_tags
}

# 3. Workload Identity Federation & CI/CD Service Account
module "iam_wif" {
  source      = "../../modules/iam_wif"
  project_id  = var.project_id
  environment = local.environment
  github_repo = var.github_repo
}

# 4. Cloud SQL for PostgreSQL 16 (Private IP Only, Scale-to-Zero Friendly)
module "cloud_sql" {
  source              = "../../modules/cloud_sql"
  project_id          = var.project_id
  region              = var.region
  environment         = local.environment
  network_id          = module.vpc.network_id
  vpc_connection_id   = module.vpc.private_vpc_connection_id
  database_version    = var.db_version
  tier                = var.db_tier
  availability_type   = var.db_availability_type
  disk_size           = var.db_disk_size
  pitr_enabled        = var.db_pitr_enabled
  retained_backups    = var.db_retained_backups
  deletion_protection = var.db_deletion_protection
  database_name       = var.db_name
  database_user       = var.db_user
}

# 5. Cloud Run v2 Services (API, Web, Worker - Scale-to-Zero Configured)
module "cloud_run" {
  source                 = "../../modules/cloud_run"
  project_id             = var.project_id
  region                 = var.region
  environment            = local.environment
  vpc_connector_id       = module.vpc.connector_id
  vpc_egress             = "PRIVATE_RANGES_ONLY"
  database_secret_id     = module.cloud_sql.db_secret_id
  tasks_topic_name       = local.tasks_topic_name
  task_events_topic_name = local.task_events_topic_name

  # API Service
  api_image         = var.api_image
  api_min_instances = var.api_min_instances
  api_max_instances = var.api_max_instances
  api_cpu           = var.api_cpu
  api_memory        = var.api_memory

  # Web Service
  web_image         = var.web_image
  web_min_instances = var.web_min_instances
  web_max_instances = var.web_max_instances
  web_cpu           = var.web_cpu
  web_memory        = var.web_memory

  # Worker Service
  worker_image         = var.worker_image
  worker_min_instances = var.worker_min_instances
  worker_max_instances = var.worker_max_instances
  worker_cpu           = var.worker_cpu
  worker_memory        = var.worker_memory
}

# 6. Cloud Pub/Sub Event Backbone & Dead-Letter Ingestion
module "pubsub" {
  source                 = "../../modules/pubsub"
  project_id             = var.project_id
  region                 = var.region
  environment            = local.environment
  tasks_topic_name       = local.tasks_topic_name
  task_events_topic_name = local.task_events_topic_name
  dead_letter_topic_name = local.dead_letter_topic_name
  worker_push_endpoint   = "${module.cloud_run.worker_uri}/events/push"
  worker_service_name    = module.cloud_run.worker_name
}
