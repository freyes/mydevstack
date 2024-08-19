#!/usr/bin/env sh

test -f /home/ubuntu/.ssh/id_rsa.pub || ssh-keygen
openstack network create admin_net
openstack subnet create --subnet-range 10.20.20.0/24 --network admin_net admin_subnet
openstack keypair create --public-key /home/ubuntu/.ssh/id_rsa.pub testkey

openstack coe cluster template create k8s-cluster-template \
    --image fedora-coreos-35.20220116.3.0-openstack.x86_64 \
    --keypair testkey \
    --external-network public \
    --flavor m1.small  \
    --network-driver flannel \
    --coe kubernetes

openstack coe cluster create \
    --cluster-template k8s-cluster-template \
    --timeout 120 \
    --fixed-network private \
    k8scluster
