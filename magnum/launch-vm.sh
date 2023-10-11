#!/bin/bash -eux


lxc init --vm j devstack
lxc config set devstack limits.cpu 4
lxc config set devstack limits.memory 32GiB
lxc config device override devstack root size=60GiB
lxc config device add devstack projectsdir disk source=$HOME/Projects path=/mnt/Projects
lxc start devstack

until lxc exec devstack -- sh -c "cloud-init status --wait"; do sleep 1;done

ssh devstack.lxd "sudo mkdir /opt/stack; \
    sudo chown ubuntu: /opt/stack; \
    git clone https://opendev.org/openstack/devstack /home/ubuntu/devstack; \
    ln -s /mnt/Projects/openstack/mydevstack/magnum/local.conf /home/ubuntu/devstack/ ; \
    byobu-enable"
RESOLVE_CONF_FILE=$(mktemp)
cat <<EOF > $RESOLVE_CONF_FILE
[Resolve]
DNS=10.37.127.1
Domains=~.
EOF
scp $RESOLVE_CONF_FILE devstack.lxd:/tmp/dns.conf
ssh devstack.lxd "sudo cp /tmp/dns.conf /etc/systemd/resolved.conf; \
    sudo systemctl restart systemd-resolved.service"
