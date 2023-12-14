variable "BaseName" {
    description = "The base name for all resources created by this template"  
}

variable "Region" {
    description = "The region to deploy resources into"
}

variable "LogAnalyticsWorkspaceId" {
    description = "The ID of the Log Analytics workspace to use for cluster logging"
}

variable "ADMINUSER" {
    description = "Username for admin account on all nodes"
}

variable "SSHKEY" {
    description = "Path to the public key to associate with the admin account on linux nodes"
}

variable "WINDOWSADMINPASSWORD" {
    description = "Password to use for the admin account on windows nodes"
}