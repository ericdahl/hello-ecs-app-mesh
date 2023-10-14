resource "aws_appmesh_virtual_gateway" "default" {
  name      = local.name
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }



    }

  }
}

resource "aws_appmesh_gateway_route" "default" {
  mesh_name            = aws_appmesh_mesh.default.name
  name                 = local.name
  virtual_gateway_name = aws_appmesh_virtual_gateway.default.name

  spec {
    http_route {

      match {
        prefix = "/"
      }

      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.counter.name

          }
        }
      }
    }
  }
}