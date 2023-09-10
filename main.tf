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

#resource "aws_appmesh_virtual_gateway" "default" {
#  mesh_name = aws_appmesh_mesh.default.name
#  name      = local.name
#}

resource "aws_appmesh_virtual_router" "redis" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "redis"

  spec {
    listener {
      port_mapping {
        port     = 6379
        protocol = "tcp"
      }
    }

  }
}

resource "aws_appmesh_virtual_service" "counter" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "counter.apps.local"

  spec {

  }
}

resource "aws_appmesh_virtual_node" "redis" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "redis"

  spec {
    listener {
      port_mapping {
        port     = 6379
        protocol = "tcp"
      }
    }

    service_discovery {
      dns {
        hostname = "redis.apps"
      }
    }
  }
}

resource "aws_appmesh_route" "redis" {
  mesh_name            = aws_appmesh_mesh.default.name
  name                 = "redis"
  virtual_router_name = aws_appmesh_virtual_router.redis.name

  spec {

    tcp_route {
      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.redis.name
          weight       = 100
        }
      }
    }
  }
}
