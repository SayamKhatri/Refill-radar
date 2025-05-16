resource "time_sleep" "wait_for_iam_propagation" {
  depends_on     = [aws_iam_role_policy_attachment.dms_vpc_access_policy]
  create_duration = "40s"          
}


