
# firewall
resource "proxmox_virtual_environment_cluster_firewall" "cluster" {
  enabled        = true
  forward_policy = "ACCEPT"
}


# Active le backend nftables sur pve1
resource "proxmox_node_firewall" "node" {
  node_name         = var.node_name
  enabled           = true
  nftables          = true
  log_level_forward = "info"
}


resource "proxmox_virtual_environment_firewall_rules" "node" {
  node_name = var.node_name

  rule {
    type    = "in"
    action  = "ACCEPT"
    source  = "10.8.0.0/24"
    dest    = "${var.proxmox_host_ip}/32"
    log     = "info"
    comment = "V vpn wireguard vers ui proxmox"
    enabled = true
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    source  = "0.0.0.0/0"
    dport   = "51820"
    proto   = "udp"
    log     = "info"
    comment = "vpn wireguard public"
    enabled = true
  }

  rule {
    type    = "forward"
    action  = "ACCEPT"
    source  = "172.16.10.12/32"
    dest    = "192.168.10.13/32"
    log     = "info"
    comment = "V cloudflared vers caddy"
    enabled = true
  }

  rule {
    type    = "forward"
    action  = "ACCEPT"
    source  = "172.16.10.0/24"
    dest    = "192.168.10.14/32"
    dport = "9090"
    proto   = "tcp"
    log     = "info"
    comment = "V pubvnet1 vers monitoring (Prometheus restreint uniquement en write avec reverse proxy Caddy)"
    enabled = true
  }

  rule {
    type    = "forward"
    action  = "ACCEPT"
    source  = "172.16.10.0/24"
    dest    = "192.168.10.14/32"
    dport = "3100"
    proto   = "tcp"
    log     = "info"
    comment = "V pubvnet1 vers monitoring (Loki restreint uniquement en write avec reverse proxy Caddy)"
    enabled = true
  }

  rule {
    type    = "forward"
    action  = "ACCEPT"
    source  = "172.16.10.0/24"
    dest    = "192.168.10.12/32"
    dport   = "53"
    proto   = "udp"
    log     = "info"
    comment = "V pubvnet1 vers coredns DNS UDP"
    enabled = true
  }

  rule {
    type    = "forward"
    action  = "ACCEPT"
    source  = "172.16.10.0/24"
    dest    = "192.168.10.12/32"
    dport   = "53"
    proto   = "tcp"
    log     = "info"
    comment = "V pubvnet1 vers coredns DNS TCP"
    enabled = true
  }

  rule {
    type    = "forward"
    action  = "DROP"
    source  = "172.16.10.0/24"
    dest    = "192.168.10.0/24"
    log     = "info"
    comment = "X pubvnet1 vers prvvnet1 en général"
    enabled = true
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    source = var.proxmox_lan_subnet
    dest   = ""
    # dport = destination port
    dport   = "51820"
    proto   = "udp"
    log     = "info"
    comment = "V réseau local vers VPN"
    enabled = true
  }

  rule {
    type    = "in"
    action  = "ACCEPT" 
    source  = "0.0.0.0/0"
    dport   = "51820"
    proto   = "udp"
    log     = "info"

    # l'authentification wireguard est toujours conditionnée à un échange clé publique / privée + udp
    # l'idée c'est d'autoriser si possible le moins de source d'ip possible quand même, donc si possible savoir à l'avance l'ip publique de là ou on va (ou alors par exemple whitelist les réseaux 4G)
    comment = "V Internet vers VPN WireGuard public"
    enabled = true
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    source = "192.168.10.13/32"
    dest   = "${var.proxmox_host_ip}/32"
    # dport = destination port
    dport   = "51821"
    proto   = "tcp"
    log     = "info"
    comment = "V caddy vers UI wireguard (réseau privé, site privé vpn.priv.{{ domain }})"
    enabled = true
  }


  depends_on = [
    proxmox_virtual_environment_cluster_firewall.cluster,
    proxmox_node_firewall.node
  ]
}

# La VM du backend Terraform appartient à la couche bootstrap donc on recherche son nom dans l'existant
# services d'administration à protéger
# tout est isolé, le seul trafic autorisé sera de caddy vers leurs ports
locals {
  caddy_source = "192.168.10.13/32"

  caddy_backends = {
    komodo = {
      guest_type = "vm"
      guest_id   = module.komodo.vm_id
      ports      = ["80", "9120"]
    }
    monitoring = {
      guest_type = "lxc"
      guest_id   = module.monitoring.lxc_id
      ports      = ["3000", "8080"]
    }
    authentik = {
      guest_type = "vm"
      guest_id   = module.authentik.vm_id
      ports      = ["9000"]
    }
    terraform_backend = {
      guest_type = "vm"
      guest_id   = 118
      ports      = ["8080"]
    }
  }

}

resource "proxmox_virtual_environment_firewall_rules" "caddy_backends" {
  for_each = merge(local.caddy_backends, local.fork_caddy_backends)

  node_name    = var.node_name
  vm_id        = each.value.guest_type == "vm" ? each.value.guest_id : null
  container_id = each.value.guest_type == "lxc" ? each.value.guest_id : null

  rule {
    type    = "in"
    action  = "ACCEPT"
    source  = local.caddy_source
    dport   = join(",", each.value.ports)
    proto   = "tcp"
    comment = "V caddy vers ${each.key}"
    enabled = true
  }

  rule {
    type    = "in"
    action  = "DROP"
    dport   = join(",", each.value.ports)
    proto   = "tcp"
    comment = "X tout vers ${each.key}"
    enabled = true
  }

  depends_on = [
    proxmox_virtual_environment_cluster_firewall.cluster,
    proxmox_node_firewall.node,
  ]
}
