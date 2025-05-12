resource "aws_lambda_function" "inventory_alert_handler" {
  function_name = "inventory-alert-handler"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime

  filename         = "../lambda/inventory_alert_handler.zip"
  source_code_hash = filebase64sha256("../lambda/inventory_alert_handler.zip")

layers = [
  "arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:28"
]


  environment {
    variables = {
      SNS_TOPIC_ARN  = aws_sns_topic.stockout_alerts.arn
      DYNAMODB_TABLE = aws_dynamodb_table.stockout_alerts.name
      S3_BUCKET      = "inventory-thresholds"
      S3_KEY         = "product_thresholds.csv"
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.inventory_stream.arn
  function_name     = aws_lambda_function.inventory_alert_handler.arn
  starting_position = "LATEST"
  batch_size        = 1

  depends_on = [
    aws_lambda_function.inventory_alert_handler,
    aws_kinesis_stream.inventory_stream
  ]
}
