resource "aws_appmesh_virtual_router" "counter" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "counter"

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "tcp"
      }
    }

  }
}

resource "aws_appmesh_virtual_node" "counter" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "counter"

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "tcp"
      }
    }

    service_discovery {
      dns {
        hostname = "counter.apps"
      }
    }
  }
}

resource "aws_appmesh_route" "counter" {
  mesh_name            = aws_appmesh_mesh.default.name
  name                 = "counter"
  virtual_router_name = aws_appmesh_virtual_router.counter.name

  spec {

    tcp_route {
      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.counter.name
          weight       = 100
        }
      }
    }
  }
}
