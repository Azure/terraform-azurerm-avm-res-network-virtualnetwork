variable "location" {
  type        = string
  default     = "eastus"
  description = "The telemetry-only region passed to the region selector; resources use a selected eligible region."
  nullable    = false
}
