terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  service_account_key_file = "key.json"
}

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name = "subnet1"
  network_id = "${yandex_vpc_network.network1.id}"
  zone = "ru-central1-a"
  v4_cidr_blocks = ["192.168.1.0/24"]
  route_table_id = yandex_vpc_route_table.nat-route-table.id
}

resource "yandex_vpc_subnet" "subnet2" {
  name = "subnet2"
  network_id = "${yandex_vpc_network.network1.id}"
  zone = "ru-central1-b"
  v4_cidr_blocks = ["192.168.2.0/24"]
  route_table_id = yandex_vpc_route_table.nat-route-table.id
}

resource "yandex_vpc_subnet" "subnet3" {
  name = "subnet3"
  network_id = "${yandex_vpc_network.network1.id}"
  zone = "ru-central1-b"
  v4_cidr_blocks = ["192.168.3.0/24"]
  route_table_id = yandex_vpc_route_table.nat-route-table.id
}

resource "yandex_vpc_gateway" "nat-gateway" {
  name        = "nat-gateway"  
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat-route-table" {
  network_id = yandex_vpc_network.network1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id     = yandex_vpc_gateway.nat-gateway.id
  }
}

resource "yandex_compute_instance" "web-nginx-1" {
  name = "web-nginx-1"
  platform_id = "standard-v1"
  zone = "ru-central1-a"
  hostname = "web-nginx-1"
  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd801rku4j14mv7fs703"
      size = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet1.id
    nat        = false
    ip_address = "192.168.1.10"
  }
  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }

}

resource "yandex_compute_instance" "web-nginx-2" {
  name = "web-nginx-2"
  platform_id = "standard-v1"
  zone        = "ru-central1-b"
  hostname = "web-nginx-2"
  scheduling_policy {
    preemptible = true
  }  
  
  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd801rku4j14mv7fs703"
      size = 10
    }
  }
  
  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet2.id
    nat        = false
    ip_address = "192.168.2.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }

}

resource "yandex_compute_instance" "zabbix" {
  name     = "zabbix"
  zone     = "ru-central1-a"
  hostname = "zabbix"
  platform_id = "standard-v3"
  scheduling_policy {
    preemptible = true
  }
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd801rku4j14mv7fs703"
      size     = 10
    }
  }
  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet1.id
    nat        = true
    ip_address = "192.168.1.5"
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_instance" "elastic" {
  name     = "elast"
  zone     = "ru-central1-a"
  hostname = "elastic"
  platform_id = "standard-v3"
  scheduling_policy {
    preemptible = true
  }
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd801rku4j14mv7fs703"
      size     = 10
    }
  }
  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet1.id
    nat        = false
    ip_address = "192.168.1.15"
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_instance" "kibana" {
  name     = "kibana"
  zone     = "ru-central1-a"
  hostname = "kibana"
  platform_id = "standard-v3"
  scheduling_policy {
    preemptible = true
  }
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd801rku4j14mv7fs703"
      size     = 10
    }
  }
  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet1.id
    nat        = true
    ip_address = "192.168.1.20"
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_instance" "bastion-host" {

  name     = "bastion-host"
  zone     = "ru-central1-b"
  hostname = "bastin-host"
  platform_id = "standard-v3"
  scheduling_policy {
    preemptible = true
  }
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd801rku4j14mv7fs703"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet3.id
    dns_record {
      fqdn = "bastion-gw.srv."
      ttl  = 300
    }
    nat                = true
    security_group_ids = [yandex_vpc_security_group.gw.id]
    ip_address         = "192.168.3.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_vpc_address" "addr1" {
  name = "addr1"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}


resource "yandex_alb_target_group" "tg1" {
  name = "tg1"

  target {
    subnet_id  = yandex_compute_instance.web-nginx-1.network_interface.0.subnet_id
    ip_address = yandex_compute_instance.web-nginx-1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_compute_instance.web-nginx-2.network_interface.0.subnet_id
    ip_address = yandex_compute_instance.web-nginx-2.network_interface.0.ip_address
  }
}

resource "yandex_alb_backend_group" "bg1" {
  name = "bg1"

  http_backend {
    name             = "backend1"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_alb_target_group.tg1.id}"]

    load_balancing_config {
      panic_threshold = 9
    }
    healthcheck {
      timeout             = "5s"
      interval            = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "router1" {
  name = "router1"
}

resource "yandex_alb_virtual_host" "vh1" {
  name           = "vh1"
  http_router_id = yandex_alb_http_router.router1.id

  route {
    name = "route1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.bg1.id
        timeout          = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "alb1" {
  name               = "alb1"
  network_id         = yandex_vpc_network.network1.id
  security_group_ids = [yandex_vpc_security_group.balancer.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet2.id
    }
  }

  listener {
    name = "listener1"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.addr1.external_ipv4_address[0].address
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.router1.id
      }
    }
  }
}

resource "yandex_vpc_security_group" "balancer" {
  name       = "balancer"
  network_id = yandex_vpc_network.network1.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}

resource "yandex_vpc_security_group" "private" {
  name       = "private"
  network_id = yandex_vpc_network.network1.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "balancer"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "elasticsearch"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9200
  }

  ingress {
    protocol          = "ANY"
    description       = "any"
    security_group_id = yandex_vpc_security_group.gw.id
  }

  ingress {
    protocol       = "TCP"
    description    = "filebeat"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5044
  }

  ingress {
    protocol       = "TCP"
    description    = "filebeat"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5043
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10051
  }


}

resource "yandex_vpc_security_group" "public" {
  name       = "public"
  network_id = yandex_vpc_network.network1.id


  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }


  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10051
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol          = "ANY"
    description       = "any"
    security_group_id = yandex_vpc_security_group.gw.id
  }

}


resource "yandex_vpc_security_group" "gw" {
  name       = "gw"
  network_id = yandex_vpc_network.network1.id


  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
}

locals {
  disk_ids = [
    yandex_compute_instance.elastic.boot_disk.0.disk_id,
    yandex_compute_instance.web-nginx-1.boot_disk.0.disk_id,
    yandex_compute_instance.web-nginx-2.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id,
    yandex_compute_instance.bastion-host.boot_disk.0.disk_id
  ]
}

resource "yandex_compute_snapshot_schedule" "snapshots" {
  name = "snapshots"

  schedule_policy {
    expression = "0 10 * * *"
  }

  snapshot_count = 7

  snapshot_spec {
    description = "Ежедневный снимок"
    labels = {
      environment = "production"
    }
  }

  disk_ids = local.disk_ids
}