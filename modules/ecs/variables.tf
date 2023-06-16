variable "name" {}
variable "repo" {
  type = list
  description = "List of repos"
}
variable "policies" {
  type = list
  description = "Fargate task role policies"
}
variable "container_insights_enabled" {
  type = string
  description = "Switchs aws container insights on or off"
}