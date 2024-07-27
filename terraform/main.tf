# Artifact Registry Configuration
resource "google_artifact_registry_repository" "nestjs-app" {
  location      = var.region
  repository_id = "nestjs-app"
  description   = "Artifact registry for storing docker artifacts"
  format        = "DOCKER"
}

# Staging GKE Cluster
resource "google_container_cluster" "staging" {
  name             = "staging"
  location         = var.region
  enable_autopilot = true
  deletion_protection = false
}

# Production GKE Cluster
resource "google_container_cluster" "production" {
  name             = "production"
  location         = var.region
  enable_autopilot = true
  deletion_protection = false
}

# Cloud Build configuration
resource "google_cloudbuild_trigger" "nestjs-app-trigger" {
  name = "nestjs-app-trigger"
  trigger_template {
    branch_name = "master"
    repo_name   = "nestjs-app-gke"
  }
#  github {
#    owner = "mmdcloud"
#    name  = "nestjs-app-gke"
#    push {
#      branch = "master"
#    }
#  }
  ignored_files   = [".gitignore"]
 # service_account = "custom-ground-424107-q4@appspot.gserviceaccount.com"
  filename        = "cloudbuild.yaml"
}

# Cloud Deploy Delivery Pipeline
resource "google_clouddeploy_delivery_pipeline" "nestjs-app" {
  name        = "nestjs-app"
  location    = var.region
  description = "Nest.js App Deployment Pipeline"
  serial_pipeline {
    stages {
      target_id = "staging"
      profiles  = ["staging"]
    }
    stages {
      target_id = "production"
      profiles  = ["production"]
    }
  }
}

# Cloud Deploy Target
resource "google_clouddeploy_target" "staging" {
  name        = "staging"
  location    = var.region
  description = "Staging environment"
  gke {
    cluster = "projects/${var.project_id}/locations/${var.region}/clusters/staging"
  }
}

# Cloud Deploy Target
resource "google_clouddeploy_target" "production" {
  name        = "production"
  location    = var.region
  description = "Production environment"
  gke {
    cluster = "projects/${var.project_id}/locations/${var.region}/clusters/production"
  }
}
