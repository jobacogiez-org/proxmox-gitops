# la couche "bootstrap" doit être appliquée auparavant, car comprenant les sous-réseaux et la VM template pour accélérer les créations d'instances. Ce sont tant de composants dont a besoin cette couche pour être efficace/sécurisée

module "minimal-backup" {
  source  = "../../../modules/backup"
  storage = var.backup_storage
}

# déploiement runner dispo en playbook
module "gh-runner" {
  source = "../../../modules/vm"

  name                = "gh-runner"
  username            = "admin"
  node_name           = var.node_name
  vm_id               = 111
  vm_template_id      = 9000
  vm_ip               = "192.168.10.11"
  network_gateway     = "192.168.10.1"
  dns_servers         = ["192.168.10.12", "1.1.1.1", "8.8.8.8"]
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage
  backup_datastore_id = var.backup_storage

  cpu       = 4
  memory    = 8192
  disk_size = 40

  bridge = "prvvnet1"

  user_data_raw = templatefile("${path.root}/../../../../services/base-vm/cloud-init.yml", {
    hostname       = "gh-runner"
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })
}

# sert notamment aux accès privés / domaines arbitraires
module "coredns" {
  source              = "../../../modules/lxc"
  name                = "coredns"
  node_name           = var.node_name
  lxc_id              = 112
  lxc_ip              = "192.168.10.12"
  network_gateway     = "192.168.10.1"
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage


  cpu       = 1
  memory    = 512
  disk_size = 5

  bridge = "prvvnet1"
}


# (wireguard se fait sur l'hôte proxmox pour fluidifier les accès réseau)

# https://caddyserver.com/docs/install
# https://github.com/caddyserver/caddy
module "caddy" {
  source = "../../../modules/lxc"

  name                = "caddy"
  node_name           = var.node_name
  lxc_id              = 113
  lxc_ip              = "192.168.10.13"
  network_gateway     = "192.168.10.1"
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage


  cpu       = 1
  memory    = 512
  disk_size = 10

  bridge = "prvvnet1"
}

# cf dossier monitoring
module "monitoring" {
  source = "../../../modules/lxc"

  name                = "monitoring"
  node_name           = var.node_name
  lxc_id              = 114
  lxc_ip              = "192.168.10.14"
  network_gateway     = "192.168.10.1"
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage


  cpu       = 2
  memory    = 2048
  disk_size = 35

  bridge = "prvvnet1"
  firewall = true
}

# https://komo.do/docs/setup
module "komodo" {
  source = "../../../modules/vm"

  name                = "komodo"
  username            = "admin"
  node_name           = var.node_name
  vm_id               = 211
  vm_template_id      = 9000
  vm_ip               = "172.16.10.11"
  network_gateway     = "172.16.10.1"
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage
  backup_datastore_id = var.backup_storage

  cpu       = 3
  memory    = 4096
  disk_size = 50

  bridge = "pubvnet1"
  firewall = true

  user_data_raw = templatefile("${path.root}/../../../../services/komodo/cloud-init.yml", {
    hostname       = "komodo"
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })
}

module "cloudflared" {
  source = "../../../modules/lxc"

  name                = "cloudflared"
  node_name           = var.node_name
  lxc_id              = 212
  lxc_ip              = "172.16.10.12"
  network_gateway     = "172.16.10.1"
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage


  cpu       = 1
  memory    = 256
  disk_size = 8

  bridge = "pubvnet1"
}

# https://docs.goauthentik.io/install-config/install/docker-compose/
module "authentik" {
  source = "../../../modules/vm"
  name                = "authentik"
  username            = "admin"
  node_name           = var.node_name
  vm_id               = 116
  vm_template_id      = 9000
  vm_ip               = "192.168.10.16"
  network_gateway     = "192.168.10.1"
  ssh_public_key_path = var.ssh_public_key_path
  target_datastore_id = var.storage
  backup_datastore_id = var.backup_storage

  cpu       = 1
  memory    = 2048
  disk_size = 10

  bridge = "prvvnet1"
  firewall = true

  user_data_raw = templatefile("${path.root}/../../../../services/base-vm/cloud-init.yml", {
    hostname       = "authentik"
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })
}
