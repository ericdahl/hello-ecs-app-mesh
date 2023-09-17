resource "aws_ecs_task_definition" "counter" {
  family = "counter"

  requires_compatibilities = ["EC2"]

  execution_role_arn = aws_iam_role.counter_task_execution.arn

  task_role_arn = aws_iam_role.counter_task.arn

  network_mode = "awsvpc"
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
#      dependsOn: {
#        containerName = "envoy"
#        condition = "HEALTHY"
#      },
      environment : [
        {
          "name" : "SPRING_REDIS_HOST",
          "value": "redis.apps" # direct to service-discovery DNS zone
#          "value" : "redis" # FIXME once envoy sidecar set up
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.counter.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "counter"
        }
      }
    },
    {
      cpu: 0,
      environment: [
        {
          "name": "APPMESH_VIRTUAL_NODE_NAME",
          "value": "mesh/apps/virtualNode/redis"
        }
      ],
      memory: 500,
      image: "840364872350.dkr.ecr.us-east-1.amazonaws.com/aws-appmesh-envoy:v1.26.4.0-prod",
      healthCheck: {
        retries: 3,
        command: [
          "CMD-SHELL",
          "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
        ],
        timeout: 2,
        interval: 5,
        startPeriod: 10
      },
      essential: true,
      links: null,
      hostname: null,
      extraHosts: null,
      pseudoTerminal: null,
      user: "1337",
      name: "envoy"
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

resource "aws_cloudwatch_log_group" "counter" {
  name              = "/${local.name}/counter"
  retention_in_days = 1
}

resource "aws_ecs_service" "counter" {
  name    = "counter"
  cluster = aws_ecs_cluster.default.name

  desired_count = 2

  enable_execute_command = true

  network_configuration {

    # for demo purposes only; no private subnets here
    # to save costs on NAT GW, speed up deploys, etc
    # only works for Fargate
#    assign_public_ip = true

    subnets = [
      aws_subnet.public.id
    ]

    security_groups = [
      aws_security_group.counter.id
    ]
  }

  task_definition = aws_ecs_task_definition.counter.arn

  # faster deploys, but has downtime
  deployment_minimum_healthy_percent = 0

  depends_on = [aws_ecs_service.redis]
}

resource "aws_cloudwatch_log_group" "counter_ecs_service_connect" {
  name              = "/ecs/counter"
  retention_in_days = 1
}

resource "aws_security_group" "counter" {
  name   = "counter"
  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "counter_egress_all" {
  security_group_id = aws_security_group.counter.id

  type = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
  description = "allows ECS task to make egress calls"
}

resource "aws_security_group_rule" "counter_ingress_admin" {
  security_group_id = aws_security_group.counter.id

  type = "ingress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = [var.admin_cidr]
}

# for testing
resource "aws_security_group_rule" "counter_ingress_vpc" {
  security_group_id = aws_security_group.counter.id

  type = "ingress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = [aws_vpc.default.cidr_block]
}

resource "aws_iam_role" "counter_task_execution" {
  name               = "counter-task-execution"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role" "counter_task" {
  name               = "counter-task"
  assume_role_policy = data.aws_iam_policy_document.role_assume_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "counter_task_ecs_exec" {
  role       = aws_iam_role.counter_task.name
  policy_arn = aws_iam_policy.ecs_task_exec.arn
}

resource "aws_iam_role_policy_attachment" "counter_task_execution" {
  role       = aws_iam_role.counter_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
#
#data "aws_network_interface" "counter" {
#  for_each = toset(data.aws_network_interfaces.counter.ids)
#  id = each.key
#}
#
#data "aws_network_interfaces" "counter" {
#  filter {
#    name   = "group-id"
#    values = [aws_security_group.counter.id]
#  }
#}

#output "counter_eni" {
#  value = [ for eni in data.aws_network_interface.counter : eni.association[0].public_ip ]
#}