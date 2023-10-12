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
  - systemctl enable nfs-server httpd
  - systemctl start nfs-server httpd
  - mkdir -p /export && chmod -R 777 /export
