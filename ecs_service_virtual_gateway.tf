resource "aws_ecs_task_definition" "virtual_gateway" {
  family = "virtual_gateway"

  execution_role_arn       = aws_iam_role.virtual_gateway_task_execution.arn
  task_role_arn            = aws_iam_role.virtual_gateway_task.arn

  network_mode = "awsvpc"
  container_definitions = jsonencode([
    {
      cpu : 0,
      environment : [
        {
          "name" : "APPMESH_RESOURCE_ARN",
          "value" : aws_appmesh_virtual_gateway.default.arn
        }
      ],
      memory : 500,
      image : "public.ecr.aws/appmesh/aws-appmesh-envoy:v1.26.4.0-prod"
      portMappings = [
        {
          name          = "envoy"
          protocol      = "tcp"
          containerPort = 8080
          hostPort      = 8080
        }
      ],
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
      essential : true,
      name : "envoy"
    }
  ])

  cpu    = 256
  memory = 512
}

resource "aws_cloudwatch_log_group" "virtual_gateway" {
  name              = "/${local.name}/virtual_gateway"
  retention_in_days = 1
}

resource "aws_ecs_service" "virtual_gateway" {
  name    = "virtual_gateway"
  cluster = aws_ecs_cluster.default.name

  desired_count = 1

  enable_execute_command = true

  service_registries {
    registry_arn = aws_service_discovery_service.virtual_gateway.arn
  }

  network_configuration {

    # for demo purposes only; no private subnets here
    # to save costs on NAT GW, speed up deploys, etc
    # only works for Fargate
    #    assign_public_ip = true

    subnets = [
      aws_subnet.private.id
      #      aws_subnet.public.id # fargate
    ]

    security_groups = [
      aws_security_group.virtual_gateway.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.virtual_gateway.arn
    container_name   = "envoy"
    container_port   = 8080
  }

  task_definition = aws_ecs_task_definition.virtual_gateway.arn

  # faster deploys, but has downtime
  deployment_minimum_healthy_percent = 0
}

resource "aws_cloudwatch_log_group" "virtual_gateway_ecs_service_connect" {
  name              = "/ecs/virtual_gateway"
  retention_in_days = 1
}

resource "aws_security_group" "virtual_gateway" {
  name   = "virtual_gateway"
  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "virtual_gateway_egress_all" {
  security_group_id = aws_security_group.virtual_gateway.id

  type = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
  description = "allows ECS task to make egress calls"
}

resource "aws_security_group_rule" "virtual_gateway_ingress_admin" {
  security_group_id = aws_security_group.virtual_gateway.id

  type = "ingress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = [var.admin_cidr]
}

# for testing
resource "aws_security_group_rule" "virtual_gateway_ingress_vpc" {
  security_group_id = aws_security_group.virtual_gateway.id

  type = "ingress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = [aws_vpc.default.cidr_block]
}

resource "aws_iam_role" "virtual_gateway_task_execution" {
  name               = "virtual_gateway-task-execution"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role" "virtual_gateway_task" {
  name               = "virtual_gateway-task"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "virtual_gateway_task_ecs_exec" {
  role       = aws_iam_role.virtual_gateway_task.name
  policy_arn = aws_iam_policy.ecs_task_exec.arn
}

resource "aws_iam_role_policy_attachment" "virtual_gateway_task_execution" {
  role       = aws_iam_role.virtual_gateway_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "virtual_gateway_task_envoy" {
  role       = aws_iam_role.virtual_gateway_task.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

resource "aws_service_discovery_service" "virtual_gateway" {

  name = "virtual_gateway"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.apps.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}