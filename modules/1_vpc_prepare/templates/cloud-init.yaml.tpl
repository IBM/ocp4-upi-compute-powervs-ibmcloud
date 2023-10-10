#cloud-config
packages:
  - httpd
  - mod_ssl
  - nfs-utils
write_files:
- path: /etc/exports
  permissions: '0640'
  content: |
    /export *(rw)
runcmd:
  - systemctl enable nfs-server
  - systemctl start nfs-server
  - mkdir -p /export && chmod -R 777 /export
