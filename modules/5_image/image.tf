################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  intel_image_upload_script_path = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/image"
}

data "ibm_resource_group" "resource_group" {
  name = var.resource_group_name
}

# Dev Note: Must use global location
# allow_cleanup is automatically decided by the service-broker
# Ref: https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints
resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.name_prefix}-mac-intel-cos"
  resource_group_id = data.ibm_resource_group.resource_group.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_cos_bucket" "cos_bucket" {
  depends_on           = [ibm_resource_instance.cos_instance]
  bucket_name          = "${var.name_prefix}-mac-intel"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.vpc_region
  storage_class        = "smart"
}

resource "null_resource" "upload_rhcos_image" {
  depends_on = [ibm_cos_bucket.cos_bucket]

  triggers = {
    cos_bucket = ibm_cos_bucket.cos_bucket.id
  }

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${local.intel_image_upload_script_path}"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/upload_rhcos_image.sh"
    destination = "${local.intel_image_upload_script_path}/upload_rhcos_image.sh"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
echo 'Uploading rhcos image to ibmcloud'
cd "${local.intel_image_upload_script_path}"
chmod +x upload_rhcos_image.sh
./upload_rhcos_image.sh "${var.ibmcloud_api_key}" "${var.vpc_region}" "${var.resource_group_name}" "${var.name_prefix}"
echo 'Done with rhcos image uploading to ibmcloud'
EOF
    ]
  }
}

# Dev Note: required however, it may require superadmin privileges to set.
# Ref: https://github.com/openshift/installer/blob/master/data/data/ibmcloud/network/image/main.tf#L19
resource "ibm_iam_authorization_policy" "policy" {
  depends_on                  = [ibm_resource_instance.cos_instance]
  count                       = var.skip_authorization_policy_create ? 0 : 1
  source_service_name         = "is"
  source_resource_type        = "image"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = element(split(":", ibm_resource_instance.cos_instance.id), 7)
  roles                       = ["Reader"]
}

locals {
  cos_region = ibm_cos_bucket.cos_bucket.region_location
}

# Dev Note: The following message points to no authorization from VPC to Image.
# > The IAM token that was specified in the request has expired or is invalid. The request is not authorized to access the Cloud Object Storage resource.
# ibmcloud is image-create test --file cos://au-syd/mac-f672-mac-intel/mac-f672-rhcos.qcow2 --os-name rhel-coreos-stable-amd64-byol
# Ref: https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4267
# Ref: https://cloud.ibm.com/iam/authorizations/grant
resource "ibm_is_image" "worker_image_id" {
  depends_on       = [null_resource.upload_rhcos_image, ibm_cos_bucket.cos_bucket, ibm_iam_authorization_policy.policy]
  name             = "${var.name_prefix}-rhcos-img"
  href             = "cos://${local.cos_region}/${var.name_prefix}-mac-intel/${var.name_prefix}-rhcos.qcow2"
  operating_system = "rhel-coreos-stable-amd64-byol"
  resource_group   = data.ibm_resource_group.resource_group.id

  //increase timeouts as this import may be cross-region
  timeouts {
    create = "45m"
  }
}
