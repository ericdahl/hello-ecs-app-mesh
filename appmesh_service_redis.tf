resource "aws_appmesh_virtual_service" "redis" {
  name      = "redis"
  mesh_name = aws_appmesh_mesh.default.name

  spec {
    provider {
      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.redis.name
      }
    }
  }
}
