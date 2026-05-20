# ── ECR Repository ────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "blacklist" {
  name                 = "ecr-blacklist"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, { Name = "ecr-blacklist" })
}

resource "aws_ecr_lifecycle_policy" "blacklist" {
  repository = aws_ecr_repository.blacklist.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
