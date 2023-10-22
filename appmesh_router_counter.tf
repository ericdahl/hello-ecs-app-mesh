resource "aws_appmesh_virtual_router" "counter" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "counter-router"

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }
  }
}

resource "aws_appmesh_route" "counter" {
  mesh_name           = aws_appmesh_mesh.default.name
  name                = "counter"
  virtual_router_name = aws_appmesh_virtual_router.counter.name

  spec {

    http_route {

      match {
        prefix = "/"
      }

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.counter_blue.name
          weight       = 5
        }

        weighted_target {
          virtual_node = aws_appmesh_virtual_node.counter_green.name
          weight       = 100
        }

      }

    }
  }
}