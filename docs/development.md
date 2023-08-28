### Steps

Create a UPI Cluster on PowerVS
This needs to be a DHCP Network (It cannot be any other type).

curl -o bin/pvsadm https://github.com/ppc64le-cloud/pvsadm/releases/download/v0.1.11/pvsadm-darwin-arm64 -L

export IBMCLOUD_API_KEY=<API KEY>

bin/pvsadm dhcpserver create --instance-id <powervs workspace> \
    --cidr 192.168.200.0/24 \
    --dns-server 9.9.9.9 \
    --name cc-vpc-dhcp \
    --snat true

Module: 0_vpc
Precondition: A VPC Exists
Postcondition: VPC exists in the same reason

Module: 1_vpc_support
Precondition: VPC exists
Postcondition: 
Steps
- Create a subnet
- Create a Security Group
- Import the AMD64 Image
<no other things needed>
https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_image
https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_security_group
https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_subnet

Module: 2_transit_gateway
very little if any changes needed. 

Module: 3_pvs_support
All that happens here is update the worker ignition file. (and run the existing openshift commands)

Module: 4_worker
Convert to use VPC
https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_instance

Module: 5_post
Same existing post steps (just for amd64)