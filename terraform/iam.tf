resource "aws_iam_policy" "ecs_task_management" {
  name        = "mitmproxy-saas-ecs-task-management"
  description = "Allows the backend task to run and stop ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ]
        Effect   = "Allow"
        Resource = [
          aws_ecs_task_definition.mitmproxy.arn,
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task/${aws_ecs_cluster.main.name}/*"
        ]
      },
      {
        Action = [
            "ec2:DescribeNetworkInterfaces"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_management" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_management.arn
}

data "aws_caller_identity" "current" {}
