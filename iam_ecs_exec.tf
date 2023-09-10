
data "aws_iam_policy_document" "role_assume_ecs_tasks" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecs_task_exec" {

  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ecs_task_exec" {
  name = "ecs-task-exec"
  policy = data.aws_iam_policy_document.ecs_task_exec.json
}