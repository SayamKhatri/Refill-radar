resource "aws_lambda_function" "inventory_alert_handler" {
  function_name = "inventory-alert-handler"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime

  filename         = "../lambda/inventory_alert_handler.zip"  # Adjust path
  source_code_hash = filebase64sha256("../lambda/inventory_alert_handler.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN  = aws_sns_topic.stockout_alerts.arn
      DYNAMODB_TABLE = aws_dynamodb_table.stockout_alerts.name
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}