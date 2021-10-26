terraform {
  required_version = "= 1.0.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
  }
  backend "local" {
    path = "./local.terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}
