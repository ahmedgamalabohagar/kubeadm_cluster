data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

variable "public_key_path" {
  type = string
  default = "~/.ssh/k8s_lab.pub"
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project-name}-key"
  public_key = file(pathexpand(var.public_key_path))
}


resource "aws_instance" "control_node" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "c7i-flex.large"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name = aws_key_pair.main.key_name
  associate_public_ip_address = true
  lifecycle {
    ignore_changes = [ami]
  }
  tags = {
    Name = "${var.project-name}-control-node"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  user_data = <<-EOF
    #cloud-config
    hostname: control
    preserve_hostname: false
  EOF

}

resource "aws_instance" "worker_node" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "m7i-flex.large"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name = aws_key_pair.main.key_name
  associate_public_ip_address = true
  
  lifecycle {
    ignore_changes = [ami]
  }
  tags = {
    Name = "${var.project-name}-worker-node"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  user_data = <<-EOF
    #cloud-config
    hostname: worker1
    preserve_hostname: false
  EOF
}

output "control_node_public_ip" {
  value = aws_instance.control_node.public_ip
}

output "control_node_private_ip" {
  value = aws_instance.control_node.private_ip
}

output "worker_node_public_ip" {
  value = aws_instance.worker_node.public_ip
}
output "worker_node_private_ip" {
  value = aws_instance.worker_node.private_ip
}