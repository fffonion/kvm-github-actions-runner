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

variable "repo" {
  type    = string
  default = ""
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

