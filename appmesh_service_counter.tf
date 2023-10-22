resource "aws_appmesh_virtual_service" "counter" {
  name      = "counter"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
#      virtual_node {
#        virtual_node_name = aws_appmesh_virtual_node.counter.name
#      }

      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.counter.name
      }
    }
  }
}