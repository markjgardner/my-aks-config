variable "BaseName" {
    description = "The base name for all resources created by this template"  
}

variable "Region" {
    description = "The region to deploy resources into"
}

variable "AdminUser" {
    description = "Username for admin account on all nodes"
}

variable "LinuxSSHKey" {
    description = "Path to the public key to associate with the admin account on linux nodes"
    default = "~/.ssh/id_rsa.pub"
}

variable "WindowsAdminPassword" {
    description = "Password to use for the admin account on windows nodes"
}

variable "SubnetId" {
    description = "The resourceId for the preallocated subnet"
}