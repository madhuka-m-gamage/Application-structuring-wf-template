# Infrastructure as Code (Terraform) - Pass 5

> **Target Platform**: Google Cloud Platform (GCP)  
> **Topology**: Zero-Trust Multi-Tier Cloud Run & Cloud SQL on Private VPC  
> **Toolchain**: Terraform (>= 1.5.0), Google Provider (~> 5.0)  
> **Status**: Active & Production-Ready  

---

## 1. Architecture Overview

This directory contains the declarative Terraform modules and environment definitions implementing the **Pass 5 Infrastructure as Code** layer for the System Design-to-Deployment Workflow.

```mermaid
flowchart TD
    subgraph GitHub["GitHub Actions CI/CD"]
        GHA[Workflow Runner]
        OIDC[OIDC Token]
    end

    subgraph Security["Identity & Security Tier"]
        WIF[Workload Identity Pool & Provider<br/>modules/iam_wif]
        CICA[CI/CD Service Account]
        SM[(Secret Manager<br/>Database Connection URL)]
    end

    subgraph Registry["Artifact Registry"]
        AR[(Docker Repository<br/>modules/artifact_registry<br/>Immutable Tags)]
    end

    subgraph VPC["Google Cloud VPC (Custom Private Network)"]
        subgraph ServerlessVPC["Serverless VPC Access"]
            Conn[VPC Access Connector<br/>10.x.x.0/28]
        end

        subgraph Compute["Cloud Run v2 Tier"]
            Web[Web Frontend SSR/SPA<br/>Port 3000 / Ingress: All]
            API[REST API Gateway<br/>Port 8080 / Ingress: All]
            Worker[Background Worker<br/>Port 8080 / Push Invoked]
        end

        subgraph DataTier["Data & Persistence Tier"]
            CloudSQL[(Cloud SQL PostgreSQL 16<br/>Private IP Only / SSL Required)]
        end
    end

    subgraph Messaging["Event Backbone Tier"]
        TopicTasks[Pub/Sub: tasks]
        TopicEvents[Pub/Sub: task-events]
        TopicDLQ[Pub/Sub: dead-letter-topic]
        SubPush[Push Subscription<br/>Max Attempts: 5 + DLQ]
    end

    %% Auth Flow
    GHA -->|OIDC Federation| WIF
    WIF -->|Assume| CICA
    CICA -->|Deploy Container| API
    CICA -->|Deploy Container| Worker
    CICA -->|Deploy Container| Web
    CICA -->|Push Images| AR

    %% Compute & Networking Flow
    Web -->|Internal Proxy / HTTPS| API
    API -->|VPC Connector Egress| Conn
    Worker -->|VPC Connector Egress| Conn
    Conn -->|Private Service Access| CloudSQL

    %% Secret Injection
    SM -.->|Injected as Env Var| API
    SM -.->|Injected as Env Var| Worker

    %% Async Choreography
    API -->|Publish Task Created| TopicTasks
    TopicTasks -->|Push Delivery (OIDC)| SubPush
    SubPush -->|HTTPS Push /events/push| Worker
    SubPush -.->|Failures > 5 attempts| TopicDLQ
    Worker -->|Publish State Events| TopicEvents
```

---

## 2. Directory Map & Module Catalog

```
infra/
├── environments/               # Environment root configurations
│   ├── dev/                    # Development: scale-to-zero, zonal DB, cost-optimized
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   ├── staging/                # Staging: mirrors production (regional HA, warm instances)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── prod/                   # Production: regional HA, warm instances, 30d retention
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── modules/                    # Reusable, self-contained Terraform modules
│   ├── artifact_registry/      # Docker repository with tag immutability
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cloud_run/              # Cloud Run v2 (web, api, worker) with VPC connector
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cloud_sql/              # PostgreSQL 16, private IP, Secret Manager integration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam_wif/                # Workload Identity Federation & CI/CD Service Account
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── pubsub/                 # Topics, push subscription to worker, DLQ, and OIDC
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc/                    # VPC, custom subnet, private IP peering, VPC connector
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md                   # This governance & operation guide
```

### Module Responsibilities

| Module | Primary GCP Resources | Key Features |
|---|---|---|
| **`modules/vpc`** | `google_compute_network`, `google_compute_subnetwork`, `google_compute_global_address`, `google_service_networking_connection`, `google_vpc_access_connector` | Subnet flow logs, private Google access, private service networking for Cloud SQL, Serverless VPC Access connector. |
| **`modules/iam_wif`** | `google_iam_workload_identity_pool`, `google_iam_workload_identity_pool_provider`, `google_service_account`, `google_project_iam_member` | Zero static keys; GitHub Actions OIDC federation with repository assertion filtering; least-privilege deployment roles (`roles/run.admin`, `roles/artifactregistry.writer`, `roles/iam.serviceAccountUser`). |
| **`modules/artifact_registry`** | `google_artifact_registry_repository` | Format `DOCKER`, tag immutability enabled, automated labels for audit tracking. |
| **`modules/cloud_run`** | `google_cloud_run_v2_service`, `google_service_account`, `google_cloud_run_v2_service_iam_member` | Web (3000), API (8080), Worker (8080) Cloud Run v2 services; Serverless VPC egress; dynamic Secret Manager injection for `DATABASE_URL`; `/healthz` startup and liveness probes; 100% latest traffic allocation. |
| **`modules/cloud_sql`** | `google_sql_database_instance`, `google_sql_database`, `google_sql_user`, `google_secret_manager_secret`, `google_secret_manager_secret_version`, `random_password` | PostgreSQL 16; private IP only (`ipv4_enabled = false`); SSL encrypted connections; automatic daily backups and PITR; automated random credentials stored directly into Secret Manager. |
| **`modules/pubsub`** | `google_pubsub_topic`, `google_pubsub_subscription`, `google_service_account`, `google_pubsub_topic_iam_member` | Topics for `tasks`, `task-events`, and `dead-letter-topic`; push subscription to Worker with `max_delivery_attempts = 5`; OIDC token authentication; dead-letter pull subscription for forensic debugging. |

---

## 3. Environment Strategy Comparison

| Dimension | `dev` | `staging` | `prod` |
|---|---|---|---|
| **Cloud SQL Tier** | `db-custom-1-3840` (or `db-f1-micro`) | `db-custom-1-3840` | `db-custom-2-7680` |
| **Availability Type** | `ZONAL` (single zone) | `REGIONAL` (High Availability) | `REGIONAL` (High Availability) |
| **PITR & Backups** | Disabled (3 retained) | Enabled (7 retained) | Enabled (30 retained) |
| **Deletion Protection** | `false` | `true` | `true` |
| **Cloud Run Scaling** | Min: `0`, Max: `2` (Scale-to-zero) | Min: `1`, Max: `5` (Warm instances) | Min: `1`, Max: `20` (Warm instances) |
| **VPC Connector** | Min: 2, Max: 3 (`e2-micro`) | Min: 2, Max: 3 (`e2-micro`) | Min: 2, Max: 10 (`e2-standard-4`) |
| **Subnet CIDR** | `10.0.0.0/20` | `10.10.0.0/20` | `10.20.0.0/20` |
| **Connector CIDR** | `10.8.0.0/28` | `10.18.0.0/28` | `10.28.0.0/28` |

---

## 4. Prerequisites & Initial GCP Setup

Before provisioning, ensure required Google Cloud APIs are enabled on your project:

```bash
gcloud services enable \
  compute.googleapis.com \
  servicenetworking.googleapis.com \
  vpcaccess.googleapis.com \
  sqladmin.googleapis.com \
  run.googleapis.com \
  pubsub.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  --project="YOUR_PROJECT_ID"
```

---

## 5. Remote State Management (GCS Backend)

In production, Terraform state must be stored in a dedicated Google Cloud Storage bucket with versioning and object holds enabled.

### 5.1 Create State Bucket

```bash
PROJECT_ID="your-project-id"
BUCKET_NAME="${PROJECT_ID}-tfstate"

gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --location="us-central1" \
  --uniform-bucket-level-access

gcloud storage buckets update "gs://${BUCKET_NAME}" --versioning
```

### 5.2 Configure Backend

Uncomment the `backend "gcs"` block in `infra/environments/<env>/main.tf` or pass backend configuration during initialization:

```bash
cd "infra/environments/dev"

terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="prefix=terraform/state/dev"
```

---

## 6. Workload Identity Federation (WIF) Setup

Workload Identity Federation enables GitHub Actions to authenticate to GCP without long-lived service account keys:

1. The `modules/iam_wif` module creates:
   - A Workload Identity Pool: `${environment}-github-pool`
   - An OIDC Provider: `github-provider` targeting `https://token.actions.githubusercontent.com`
   - An attribute condition restricting access to your specific repository (`assertion.repository == var.github_repo`)
   - A CI/CD service account `${environment}-cicd-sa` with `roles/iam.workloadIdentityUser` binding.
2. In GitHub Actions workflows (`.github/workflows/`), authenticate using:

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ steps.infra.outputs.workload_identity_provider }}
    service_account: ${{ steps.infra.outputs.cicd_service_account_email }}
```

---

## 7. Local Planning & Execution Commands

Follow standard Terraform commands to preview and apply infrastructure:

### 7.1 Setup Variables

Copy the example variables file and adjust parameters:

```bash
cd infra/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your GCP project ID and GitHub repository name.

### 7.2 Format & Validation

```bash
# Check formatting
terraform fmt -check -recursive ../../

# Initialize providers and modules
terraform init

# Validate configuration syntax
terraform validate
```

### 7.3 Plan & Apply

```bash
# Generate deterministic execution plan
terraform plan -out=tfplan

# Apply approved plan
terraform apply tfplan
```

### 7.4 Destroy (Development Only)

```bash
terraform destroy
```

---

## 8. Non-Negotiable Invariants Enforced

* **Zero Static Secrets**: Relational database credentials are dynamically generated via `random_password` (24 characters, URL-safe alphanumeric) and stored directly into Secret Manager. Cloud Run instances resolve the database URL at runtime via `value_source.secret_key_ref`.
* **Zero Public Database Exposure**: Cloud SQL instances have `ipv4_enabled = false` and `ssl_mode = "ENCRYPTED_ONLY"`. Connections are routed strictly via private VPC peering and Serverless VPC Access connectors.
* **Dead-Letter Resiliency**: Cloud Pub/Sub subscriptions enforce a maximum delivery attempt threshold (`max_delivery_attempts = 5`) before routing poison-pill events to `dead-letter-topic` with 14-day message retention for debugging.
* **Deterministic Tag Immutability**: Artifact Registry repositories enforce `immutable_tags = true` to prevent tag overwriting and supply chain tampering.
