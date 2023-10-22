resource "aws_appmesh_virtual_router" "redis" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "redis-router"

  spec {
    listener {
      port_mapping {
        port     = 6379
        protocol = "tcp"
      }
    }
  }
}

resource "aws_appmesh_route" "redis" {
  mesh_name           = aws_appmesh_mesh.default.name
  name                = "redis"
  virtual_router_name = aws_appmesh_virtual_router.redis.name

  spec {

    tcp_route {



      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.redis_blue.name
          weight       = 5
        }

        weighted_target {
          virtual_node = aws_appmesh_virtual_node.redis_green.name
          weight       = 100
        }

      }

    }
  }
}