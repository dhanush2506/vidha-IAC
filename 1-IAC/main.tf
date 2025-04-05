#lets create a new VPC
#lets create a subnet

resource "google_compute_network" "tf-vpc" {
    name=var.vpc_name
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "tf-subnet" {
    name= "${var.vpc_name}-subnet"
    network = google_compute_network.tf-vpc.name
    region = var.region
    ip_cidr_range = var.cidr
}

#this will create firewalls for vidha-vpc

resource "google_compute_firewall" "tf-allow-ports" {
  name= var.firewall_name
  network = google_compute_network.tf-vpc.name
  dynamic "allow" {
    for_each = var.ports
    content {
      protocol = "tcp"
      ports = [allow.value]
    }
  }
  source_ranges = ["0.0.0.0/0"]
}
#Generate a SSH key pair using terraform 
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#Save the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.ssh-key.private_key_pem
  filename = "${path.module}/id_rsa"     #"/c/Users/Dhanush/OneDrive/Desktop/devops project/id_rsa" 
}

#Save the public key to a local file
resource "local_file" "public_key" {
  content  = tls_private_key.ssh-key.public_key_openssh
  filename = "${path.module}/id_rsa.pub" #"/c/Users/Dhanush/OneDrive/Desktop/devops project/id_rsa.pub" 
}
#this will create a compute engine instances which are needed for vidha infrastructure

resource "google_compute_instance" "tf-vm-instances" {
    for_each = var.instances
    name = each.key
    zone = each.value.zone
    machine_type = each.value.instance_type
    tags = [each.key]
    
    boot_disk {

    initialize_params {
      image = data.google_compute_image.ubuntu_image.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }
    network_interface {
        access_config {
        network_tier = "PREMIUM"
        }
        network = google_compute_network.tf-vpc.name
        subnetwork  = google_compute_subnetwork.tf-subnet.name
    }

    metadata = {
      ssh-keys = "${var.vm_user}:${tls_private_key.ssh-key.public_key_openssh}"
    }
    #This connection block, helps us to connect to VM Instances via ssh
    connection {
        type = "ssh" #Linux machine
        user =  var.vm_user  #"vidha1625"
        host = self.network_interface[0].access_config[0].nat_ip
        #We need to generate public and private key
        private_key = tls_private_key.ssh-key.private_key_pem #lets use the private key from TLS resource
    }

    #Provisioner
    #file, remore-exec, local-exec
    provisioner "file" {
      #if ansible machine, execute ansible.sh
      #if not, execute other.sh
      #condition ? success : failure
      source = each.key == "ansible" ? "ansible.sh" : "other.sh" #conditional
      destination = each.key == "ansible" ? "/home/${var.vm_user}/ansible.sh" : "/home/${var.vm_user}/other.sh"
    }

    #in ansible vm, ansible.sh should execute
    provisioner "remote-exec" {
      inline = [ 
        each.key == "ansible" ? "chmod +x /home/${var.vm_user}/ansible.sh && sh /home/${var.vm_user}/ansible.sh" : "echo 'skipping the command'"
       ]
    }

    }

    #data block to get image
    data "google_compute_image" "ubuntu_image" {
    family = "ubuntu-2004-lts"
    project = "ubuntu-os-cloud"
    }



