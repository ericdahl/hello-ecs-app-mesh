resource "aws_appmesh_virtual_service" "redis_green" {
  name      = "redis_green"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.redis_green.name
      }
    }
  }
}
