resource "aws_appmesh_virtual_service" "redis_blue" {
  name      = "redis_blue"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.redis_blue.name
      }
    }
  }
}
