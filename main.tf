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

  spec {
    # TODO: try removing this?
    egress_filter {
      type = "ALLOW_ALL"
    }
  }

}

#resource "aws_appmesh_virtual_gateway" "default" {
#  mesh_name = aws_appmesh_mesh.default.name
#  name      = local.name
#}


resource "aws_appmesh_virtual_service" "counter" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "counter.apps.local"

  spec {

  }
}
