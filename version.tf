terraform {
  required_version = "~>1.4.6"

  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>4.70.0"
    }
  }
}
