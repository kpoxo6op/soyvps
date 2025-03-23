# /variables.tf
#
# EXPLANATION OF THIS FILE:
# 1) Holds root-level variables used by the main.tf and module calls.
# 2) If you prefer to keep them in .env or somewhere else, that is fine too.
#

variable "ssh_public_key" {
  type        = string
  description = "Your SSH public key for the VM admin user"
  default     = ""
}

# If you want to supply your own WireGuard keys from outside (optional):
variable "wg_server_private_key" {
  type        = string
  description = "Pre-generated WireGuard server private key"
  sensitive   = true
  default     = ""
}

variable "wg_server_public_key" {
  type        = string
  description = "Pre-generated WireGuard server public key"
  default     = ""
}
