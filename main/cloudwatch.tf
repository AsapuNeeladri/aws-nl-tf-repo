resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/my-server"
  retention_in_days = 7

  tags = {
    Name        = "EC2 CloudWatch Logs"
    Environment = "lab"
  }
}