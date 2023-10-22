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