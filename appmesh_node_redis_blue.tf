resource "aws_appmesh_virtual_node" "redis_blue" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "redis_blue"

  spec {
    listener {
      port_mapping {
        port     = 6379
        protocol = "tcp"
      }
    }

    service_discovery {
      dns {
        hostname = "redis_blue.apps"
      }
    }
  }
}
