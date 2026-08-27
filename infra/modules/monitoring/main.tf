resource "aws_sns_topic" "this" {
  
  name = "alertas-instancia"
}

resource "aws_sns_topic_subscription" "this" {
  for_each = toset(var.alert_emails)
  topic_arn = aws_sns_topic.this.arn
  protocol = "email"
  endpoint = each.value
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name = "ec2-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 80
  
  dimensions = {
    InstanceId = var.instance_id
}
}
