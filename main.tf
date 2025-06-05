terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.142.0"
    }
  }
}

variable "subnet_id" {
  type        = string
  default     = "e9bl2anct10knpqerboo"
}

variable "ssh_key" {
  type        = string
}

variable "instance_name" {
  type        = string
  default     = "nginx"
}

variable "zone" {
  type        = string
  default     = "ru-central1-a"
}

variable "folder_id" {
  type        = string
  default     = "b1g25o2paqivo7ssujha"
}

resource "yandex_compute_instance" "nginx" {
  name        = var.instance_name
  platform_id = "standard-v1"
  zone        = var.zone
  folder_id   = var.folder_id
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8ll63hk9brrfbfe0tl" # Ubuntu 22.04 LTS
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
    user-data = <<-EOF
      #cloud-config
      package_update: true
      package_upgrade: true
      packages:
        - nginx
      write_files:
        - path: /usr/local/bin/write-hostname.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            echo "<h1>Server ID: $(hostname)</h1>" > /var/www/html/index.html
            if [ $? -eq 0 ]; then
              echo "Custom index.html created successfully" >> /var/log/custom-script.log
            else
              echo "Failed to create index.html" >> /var/log/custom-script.log
            fi
      runcmd:
        - [ systemctl, enable, nginx ]
        - [ systemctl, start, nginx ]
        - [ bash, /usr/local/bin/write-hostname.sh ]
        - [ systemctl, restart, nginx ]
      final_message: "Cloud-init completed"
    EOF
  }
}

output "instance_id" {
  value = yandex_compute_instance.nginx.id
}

output "internal_ip" {
  value = yandex_compute_instance.nginx.network_interface.0.ip_address
}

output "external_ip" {
  value = yandex_compute_instance.nginx.network_interface.0.nat_ip_address
}

output "subnet_id" {
  value = var.subnet_id
}