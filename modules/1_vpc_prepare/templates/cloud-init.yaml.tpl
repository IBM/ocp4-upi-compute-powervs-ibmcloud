#cloud-config
packages:
  - httpd
runcmd:
  - systemctl enable httpd
  - systemctl start httpd
