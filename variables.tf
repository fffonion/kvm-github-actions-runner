variable "name" {
  type    = string
  default = "runner"
}

variable "labels" {
  type    = string
  default = ""
}

variable "runnergroup" {
  type    = string
  default = ""
}

variable "url" {
  type    = string
  default = "url to register the runner with, like https://github.com/owner/repo or https://github.com/org"
}

variable "token" {
  type = string
}

variable "runner_version" {
  type    = string
  default = "2.301.1"
}

variable "docker_user" {
  type    = string
  default = ""
}

variable "docker_pass" {
  type    = string
  default = ""
}

