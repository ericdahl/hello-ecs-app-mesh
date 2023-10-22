resource "aws_ecs_task_definition" "counter_green" {
  family = "counter-green"

  execution_role_arn = aws_iam_role.counter_green_task_execution.arn
  task_role_arn      = aws_iam_role.counter_green_task.arn
  network_mode       = "awsvpc"

  container_definitions = jsonencode([
    {
      name  = "counter"
      image = "ericdahl/hello-ecs:6770354"
      portMappings = [
        {
          name          = "http"
          protocol      = "tcp"
          appProtocol   = "http"
          containerPort = 8080
          hostPort      = 8080
        }
      ],
      dependsOn = [
        {
          containerName = "envoy"
          condition     = "HEALTHY"
        }
      ],
      environment : [
        {
          "name" : "SPRING_REDIS_HOST",
          "value" : "redis.apps"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.counter_green.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "counter_green"
        }
      }
    },
    {
      cpu : 0,
      environment : [
        {
          "name" : "APPMESH_RESOURCE_ARN",
          "value" : aws_appmesh_virtual_node.counter_green.arn
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
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.counter_green_envoy.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "counter_green-envoy"
        }
      }
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

resource "aws_cloudwatch_log_group" "counter_green" {
  name              = "/${local.name}/counter_green"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "counter_green_envoy" {
  name              = "/${local.name}/counter_green-envoy"
  retention_in_days = 1
}

resource "aws_ecs_service" "counter_green" {
  name    = "counter_green"
  cluster = aws_ecs_cluster.default.name

  desired_count = 1

  enable_execute_command = true

  service_registries {
    registry_arn = aws_service_discovery_service.counter_green.arn
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
      aws_security_group.counter_green.id
    ]
  }

  task_definition = aws_ecs_task_definition.counter_green.arn

  # faster deploys, but has downtime
  deployment_minimum_healthy_percent = 0

  depends_on = [aws_ecs_service.redis]
}

resource "aws_security_group" "counter_green" {
  name   = "counter_green"
  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "counter_green_egress_all" {
  security_group_id = aws_security_group.counter_green.id

  type = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
  description = "allows ECS task to make egress calls"
}

resource "aws_security_group_rule" "counter_green_ingress_admin" {
  security_group_id = aws_security_group.counter_green.id

  type = "ingress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = [var.admin_cidr]
}

# for testing
resource "aws_security_group_rule" "counter_green_ingress_vpc" {
  security_group_id = aws_security_group.counter_green.id

  type = "ingress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = [aws_vpc.default.cidr_block]
}

resource "aws_iam_role" "counter_green_task_execution" {
  name               = "counter_green-task-execution"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role" "counter_green_task" {
  name               = "counter_green-task"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "counter_green_task_ecs_exec" {
  role       = aws_iam_role.counter_green_task.name
  policy_arn = aws_iam_policy.ecs_task_exec.arn
}

resource "aws_iam_role_policy_attachment" "counter_green_task_execution" {
  role       = aws_iam_role.counter_green_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "counter_green_task_envoy" {
  role       = aws_iam_role.counter_green_task.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

resource "aws_service_discovery_service" "counter_green" {

  name = "counter_green"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.apps.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}