resource "aws_appmesh_virtual_node" "counter_blue" {
  mesh_name = aws_appmesh_mesh.default.name
  name      = "counter_blue"

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }

    service_discovery {
      dns {
        hostname = "counter_blue.apps"
      }
    }

    backend {
      virtual_service {
        virtual_service_name = aws_appmesh_virtual_service.redis_blue.name
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

resource "aws_appmesh_virtual_service" "counter_blue" {
  name      = "counter_blue"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.counter_blue.name
      }
    }
  }
}