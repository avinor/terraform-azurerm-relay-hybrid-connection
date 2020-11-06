variable "name" {
  description = "Name of relay hybrid connection, if it contains illegal characters (,-_ etc) those will be truncated."
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "Azure location where resources should be deployed."
}

variable "hybrid_connections" {
  description = "List of hybrid connections"
  type = list(object({
    name          = string,
    user_metadata = string,
    keys = list(object(
      {
        name   = string,
        rights = list(string),
      }
    ))
    }
  ))
  default = []
}

variable "diagnostics" {
  description = "Diagnostic settings for those resources that support it. See README.md for details on configuration."
  type = object(
    {
      destination   = string,
      eventhub_name = string,
      logs          = list(string),
      metrics       = list(string)
    }
  )
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}
