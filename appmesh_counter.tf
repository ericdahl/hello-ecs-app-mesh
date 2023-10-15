resource "aws_appmesh_virtual_node" "counter" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "counter"

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }

    service_discovery {
      dns {
        hostname = "counter.apps"
      }
    }

    backend {
      virtual_service {
        virtual_service_name = aws_appmesh_virtual_service.redis.name
      }
    }

    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
  }
}

resource "aws_appmesh_virtual_service" "counter" {
  name      = "counter"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.counter.name
      }
    }
  }
}