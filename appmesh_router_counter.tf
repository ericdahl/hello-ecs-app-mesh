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



resource "aws_appmesh_route" "counter_header_blue" {
  mesh_name           = aws_appmesh_mesh.default.name
  name                = "counter_header_blue"
  virtual_router_name = aws_appmesh_virtual_router.counter.name

  spec {

    priority = 1

    http_route {
      match {
        prefix = "/"
        header {
          name = "color"
          match {
            exact = "blue"
          }
        }
      }

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.counter_blue.name
          weight       = 1
        }
      }
    }
  }
}

resource "aws_appmesh_route" "counter_header_green" {
  mesh_name           = aws_appmesh_mesh.default.name
  name                = "counter_header_green"
  virtual_router_name = aws_appmesh_virtual_router.counter.name

  spec {

    priority = 1

    http_route {
      match {
        prefix = "/"
        header {
          name = "color"
          match {
            exact = "green"
          }
        }
      }

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.counter_green.name
          weight       = 1
        }
      }
    }
  }
}

resource "aws_appmesh_route" "counter" {
  mesh_name           = aws_appmesh_mesh.default.name
  name                = "counter"
  virtual_router_name = aws_appmesh_virtual_router.counter.name

  spec {
    priority = 100

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
          weight       = 95
        }
      }
    }
  }
}