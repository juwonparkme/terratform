resource "aws_lambda_layer_version" "dependencies" {
  filename            = var.lambda_layer_archive_path
  source_code_hash    = filebase64sha256(var.lambda_layer_archive_path)
  layer_name          = "${local.name_prefix}-deps-${substr(filemd5(var.lambda_layer_archive_path), 0, 8)}"
  compatible_runtimes = [var.lambda_runtime]
}

resource "aws_cloudwatch_log_group" "lambda" {
  count = var.lambda_size

  name              = "/aws/lambda/${local.function_names[count.index]}"
  retention_in_days = var.log_retention_in_days

  tags = local.tags
}

resource "aws_lambda_function" "proxy" {
  count = var.lambda_size

  function_name = local.function_names[count.index]
  role          = aws_iam_role.lambda.arn

  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  architectures    = var.lambda_architectures
  source_code_hash = filebase64sha256(var.lambda_app_archive_path)
  publish          = true
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  s3_bucket = aws_s3_bucket.artifacts.id
  s3_key    = aws_s3_object.app_archive.key

  layers = [aws_lambda_layer_version.dependencies.arn]

  environment {
    variables = merge(var.environment_variables, {
      FUNCTION_INDEX = tostring(count.index)
    })
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      security_group_ids = [aws_security_group.lambda[0].id]
      subnet_ids         = local.private_subnet_ids
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = local.tags
}

resource "aws_lambda_permission" "alb" {
  count = var.lambda_size

  statement_id  = "AllowExecutionFromALB${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proxy[count.index].function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda[count.index].arn
}
