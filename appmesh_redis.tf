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

resource "aws_appmesh_virtual_service" "redis" {
  name      = "redis"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.redis.name
      }
    }
  }
}


#
#resource "aws_appmesh_route" "redis" {
#  mesh_name           = aws_appmesh_mesh.default.name
#  name                = "redis"
#  virtual_router_name = aws_appmesh_virtual_router.redis.name
#
#  spec {
#
#    tcp_route {
#      action {
#        weighted_target {
#          virtual_node = aws_appmesh_virtual_node.redis.name
#          weight       = 100
#        }
#      }
#    }
#  }
#}
#
#resource "aws_appmesh_virtual_router" "redis" {
#  mesh_name = aws_appmesh_mesh.default.name
#  name      = "redis"
#
#  spec {
#    listener {
#      port_mapping {
#        port     = 6379
#        protocol = "tcp"
#      }
#    }
#
#  }
#}