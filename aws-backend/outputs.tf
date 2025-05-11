output "kinesis_stream_name" {
  value = aws_kinesis_stream.inventory_stream.name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.stockout_alerts.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.stockout_alerts.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.inventory_alert_handler.function_name
}