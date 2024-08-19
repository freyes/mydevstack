#!/bin/bash -eux


lxc init --vm ubuntu-daily:jammy devstack
lxc config set devstack limits.cpu 4
lxc config set devstack limits.memory 32GiB
lxc config device override devstack root size=60GiB
lxc config device add devstack projectsdir disk source=$HOME/Projects path=/mnt/Projects
lxc start devstack

until lxc exec devstack -- sh -c "cloud-init status --wait"; do sleep 1;done
until host devstack.lxd;do sleep 1;done
ssh devstack.lxd "mkdir ~/.pip ; \
    sudo mkdir /root/.pip ; \
    sudo mkdir /opt/stack; \
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
PIP_CONF_FILE=$(mktemp)
cat << EOF > $PIP_CONF_FILE
[global]
index-url = http://10.37.127.1:3141/root/pypi/+simple/
trusted-host = 10.37.127.1
[search]
index = http://10.37.127.1:3141/root/pypi/
EOF
scp $PIP_CONF_FILE devstack.lxd:/tmp/pip.conf
APT_CONF_FILE=$(mktemp)
cat <<EOF > $APT_CONF_FILE
Acquire::http::proxy "http://10.37.127.1:3128/";
Acquire::https::proxy "http://10.37.127.1:3128/";
EOF
scp $APT_CONF_FILE devstack.lxd:/tmp/90-proxy.conf

ssh devstack.lxd "sudo cp /tmp/pip.conf /root/.pip/pip.conf ; \
    cp /tmp/pip.conf /home/ubuntu/.pip/pip.conf ; \
    sudo cp /tmp/dns.conf /etc/systemd/resolved.conf; \
    sudo systemctl restart systemd-resolved.service; \
    sudo cp /tmp/90-proxy.conf /etc/apt/apt.conf.d/ ; \
    until dig +short devstack.lxd > ~/host_ip ; do sleep 1;done ;\
    echo 1 | sudo tee /proc/sys/net/ipv4/conf/enp5s0/proxy_arp ; \
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward; \
    sudo iptables -t nat -A POSTROUTING -o enp5s0 -j MASQUERADE "
