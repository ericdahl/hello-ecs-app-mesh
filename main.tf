provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Name       = "hello-ecs-app-mesh"
      Repository = "https://github.com/ericdahl/hello-ecs-app-mesh"
    }
  }
}

data "aws_default_tags" "default" {}

locals {
  name = data.aws_default_tags.default.tags["Name"]
}

resource "aws_appmesh_mesh" "default" {
  name = "apps"
}

resource "aws_service_discovery_private_dns_namespace" "apps" {
  name = "apps"
  vpc  = aws_vpc.default.id
}
