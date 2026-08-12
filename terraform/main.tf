provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# --------------------------------------------------
# GitHub OIDC provider
# --------------------------------------------------

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]
}

# --------------------------------------------------
# IAM role for GitHub Actions
# --------------------------------------------------

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
    test     = "StringLike"
    variable = "token.actions.githubusercontent.com:sub"

    values = [
        "repo:${var.github_owner}@4114230/${var.github_repo}@1331792245:ref:refs/heads/main"
    ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name = "todo-app-github-actions"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# --------------------------------------------------
# ECR permissions
# --------------------------------------------------

data "aws_iam_policy_document" "github_actions_ecr" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/todo-app"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "todo-app-ecr"
  role = aws_iam_role.github_actions.id

  policy = data.aws_iam_policy_document.github_actions_ecr.json
}