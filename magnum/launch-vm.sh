#!/bin/bash -eux

lxc launch --vm -c limits.cpu=4 -c limits.memory=32GiB j devstack
until lxc exec devstack -- sh -c "cloud-init status --wait"; do sleep 1;done
lxc stop devstack
lxc config device add devstack projectsdir disk source=$HOME/Projects path=/home/ubuntu/Projects
# lxc config device add devstack eth1 nic name=eth1 nictype=bridged parent=lxdbr0
lxc start devstack
until ssh devstack.lxd test -e /home/ubuntu; do sleep 1;done
ssh devstack.lxd "sudo mkdir /opt/stack; \
    sudo chown ubuntu: /opt/stack; \
    git clone https://opendev.org/openstack/devstack /home/ubuntu/devstack; \
    ln -s /home/ubuntu/Projects/openstack/mydevstack/magnum/local.conf /home/ubuntu/devstack/"
