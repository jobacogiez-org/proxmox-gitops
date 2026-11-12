variable "proxmox_endpoint" {
  description = "Endpoint API Proxmox, exemple: https://pve.home.arpa:8006/api2/json"
  type        = string
}

variable "proxmox_api_token" {
  description = "Token API Proxmox."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Ignore la verification TLS du certificat Proxmox."
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Nom du PVE / hostname"
  type        = string
  # pas de défaut pour pas semer la confusion
}

variable "proxmox_ssh_username" {
  description = "Utilisateur SSH sur le node Proxmox. Requis pour uploader les snippets/hook scripts."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_private_key_path" {
  description = "Chemin de la cle privee SSH pour le node Proxmox."
  type        = string
  default     = "~/.ssh/proxmox_terraform"
}

variable "ssh_public_key_path" {
  description = "Chemin de la cle publique SSH a injecter dans la VM."
  type        = string
}

variable "storage" {
  description = "disque utilisé par la VM/LXC. Utiliser de préférence du ZFS raid1 avec redondance, et chiffré si possible"
  type        = string
}

variable "backup_storage" {
  description = "Stockage utilisé pour les sauvegardes, isos et snippets cloud-init."
  type        = string
  default     = "local"
}
variable "s3_access_key" {
  description = "S3 Access Key"
  type        = string
  sensitive   = true
}

variable "s3_secret_key" {
  description = "S3 Secret Key"
  type        = string
  sensitive   = true
}
