resource "aws_ecs_task_definition" "redis" {
  family = "redis"

  requires_compatibilities = ["EC2"]

  execution_role_arn = aws_iam_role.redis_task_execution.arn
  task_role_arn      = aws_iam_role.redis_task.arn
  network_mode       = "awsvpc"

  container_definitions = jsonencode([
    {
      name  = "redis"
      image = "redis:latest"
      portMappings = [
        {
          name          = "redis"
          protocol      = "tcp"
          containerPort = 6379
          hostPort      = 6379
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "redis"
        }
      }
    },
    {
      cpu : 0,
      environment : [
        {
          "name" : "APPMESH_RESOURCE_ARN",
          "value" : aws_appmesh_virtual_node.redis.arn
        }
      ],
      memory : 500,
      image : "public.ecr.aws/appmesh/aws-appmesh-envoy:v1.26.4.0-prod"
      healthCheck : {
        retries : 3,
        command : [
          "CMD-SHELL",
          "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
        ],
        timeout : 10,
        interval : 5,
        startPeriod : 10
      },
      user : "1337",
      name : "envoy"
    }
  ])

  proxy_configuration {
    container_name = "envoy"

    type = "APPMESH"
    properties = {
      AppPorts         = 8080
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = 1337
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }

  cpu    = 256
  memory = 512
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/${local.name}/redis"
  retention_in_days = 1
}

resource "aws_ecs_service" "redis" {
  name    = "redis"
  cluster = aws_ecs_cluster.default.name

  desired_count = 1

  enable_execute_command = true

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }

  network_configuration {

    # for demo purposes only; no private subnets here
    # to save costs on NAT GW, speed up deploys, etc
    #    assign_public_ip = true

    subnets = [
      aws_subnet.private.id
      #      aws_subnet.public.id # fargate
    ]

    security_groups = [
      aws_security_group.redis.id
    ]
  }

  # faster deploys, but has downtime
  deployment_minimum_healthy_percent = 0

  task_definition = aws_ecs_task_definition.redis.arn
}

resource "aws_cloudwatch_log_group" "redis_ecs_service_connect" {
  name              = "/ecs/redis"
  retention_in_days = 1
}

resource "aws_security_group" "redis" {
  name   = "redis"
  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "redis_egress_all" {
  security_group_id = aws_security_group.redis.id

  type = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
  description = "allows ECS task to make egress calls"
}

resource "aws_security_group_rule" "redis_ingress_admin" {
  security_group_id = aws_security_group.redis.id

  type = "ingress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = [var.admin_cidr]
}

resource "aws_security_group_rule" "redis_ingress_counter" {
  security_group_id = aws_security_group.redis.id

  type = "ingress"

  from_port = 6379
  to_port   = 6379
  protocol  = "tcp"

  source_security_group_id = aws_security_group.counter.id
}

resource "aws_iam_role" "redis_task_execution" {
  name               = "redis-task-execution"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "redis_task_execution" {
  role       = aws_iam_role.redis_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "redis_task" {
  name               = "redis-task"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "redis_task_ecs_exec" {
  role       = aws_iam_role.redis_task.name
  policy_arn = aws_iam_policy.ecs_task_exec.arn
}

resource "aws_iam_role_policy_attachment" "redis_task_envoy" {
  role       = aws_iam_role.redis_task.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

resource "aws_service_discovery_service" "redis" {

  name = "redis"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.apps.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}