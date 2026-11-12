resource "proxmox_download_file" "debian13" {
  node_name    = var.node_name
  datastore_id = var.backup_storage
  content_type = "import"
  overwrite    = true
  overwrite_unmanaged = true

  url       = "https://cloud.debian.org/cdimage/cloud/trixie/20260623-2518/debian-13-generic-amd64-20260623-2518.qcow2"
  file_name = "debian-13-genericcloud-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "debian13" {
  name      = "debian13-template"
  node_name = var.node_name
  vm_id     = 9000
  template  = true


  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = var.storage
    file_id      = proxmox_download_file.debian13.id
    interface    = "scsi0"
    discard      = "on"
  }

  initialization {
    datastore_id      = var.backup_storage
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  serial_device {}
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  node_name    = var.node_name
  datastore_id = var.backup_storage
  content_type = "snippets"

  source_file {
    path      = "${path.root}/../../../../services/template-vm/cloud-init.yml"
    file_name = "cloud-init.yml"
  }
}


# backend distant pour terraform notamment (Le state ne sera plus stocké en local)
# https://github.com/Clivern/Lynx
module "terraform-backend" {
  source = "../../../modules/vm"

  depends_on = [proxmox_virtual_environment_vm.debian13]

  name                = "terraform-backend"
  username            = "admin"
  node_name           = var.node_name
  vm_id               = 118
  vm_template_id      = 9000
  vm_ip               = "192.168.10.18"
  network_gateway     = "192.168.10.1"
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage
  backup_datastore_id = var.backup_storage

  cpu       = 1
  # +500Mi pour etre large
  memory    = 2560
  disk_size = 15

  bridge = "prvvnet1"
  firewall = true
  user_data_raw = templatefile("${path.root}/../../../../services/terraform-backend/cloud-init.yml", {
    hostname       = "terraform-backend"
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
    s3_access_key  = var.s3_access_key
    s3_secret_key  = var.s3_secret_key
  })
}




