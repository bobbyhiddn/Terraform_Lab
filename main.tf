terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox" # Example source, verify if correct and up to date
      version = "X.Y.Z" # Specify the appropriate version
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://your-proxmox-server:8006/api2/json"
  pm_user = "root@pam"
  pm_password = "yourpassword"
  pm_tls_insecure = true # Not recommended for production use; consider using proper TLS certificates
}

resource "proxmox_vm_qemu" "gitlab_vm" {
  name = "gitlab-server"
  target_node = "pve" # Your Proxmox node name
  clone = "template-rocky-linux" # Name of your Rocky Linux template
  cores = 4
  memory = 4096
  disk {
    size = "20G"
  }
  network {
    model = "virtio"
    bridge = "vmbr0"
  }

  # Provisioning GitLab after VM creation
  provisioner "remote-exec" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y curl policycoreutils openssh-server openssh-clients",
      "sudo dnf install -y postfix",
      "sudo systemctl start postfix",
      "sudo systemctl enable postfix",
      "curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash",
      "sudo EXTERNAL_URL='http://your_gitlab_domain_or_IP' dnf install -y gitlab-ce",
    ]
    connection {
      type = "ssh"
      user = "root" # or another user if not using root
      private_key = file("/path/to/your/private_key")
      host = self.default_ipv4_address
    }
  }
}
