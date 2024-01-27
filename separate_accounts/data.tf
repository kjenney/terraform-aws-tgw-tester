data "aws_caller_identity" "secondaccount" {
  provider  = aws.secondaccount
}

data "aws_caller_identity" "thirdaccount" {
  provider  = aws.thirdaccount
}