variable "projectid"{
    default= "aqueous-nuance-455902-b1"
}

variable "region"{
    default= "us-central1"
}

variable "vpc_name" {
  default = "vidha-ecommerce-vpc"
}

variable "cidr" {
  default = "10.1.0.0/16"
}

variable "firewall_name" {
  default = "vidha-firewall"
}

variable "ports" {
    default = [80, 8080, 8081, 9000, 22]
}

variable "instances" {
    default = {
        "jenkins-master" = {
            instance_type = "e2-medium"
            zone = "us-central1-a"
        }
        "jenkins-slave" = {
            instance_type = "n1-standard-1"
            zone = "us-central1-b"
        }
        "ansible" = {
            instance_type = "e2-medium"
            zone = "us-central1-a"
        }
    }
  
}

variable "vm_user" {
  default = "vidha1625" #-var=vm_user=<username>
}