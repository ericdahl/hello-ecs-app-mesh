resource "aws_appmesh_virtual_service" "counter_green" {
  name      = "counter_green"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.counter_green.name
      }
    }
  }
}