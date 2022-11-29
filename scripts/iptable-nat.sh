#!/bin/bash

# step 1, deploy sysctl config file
#
cat <<'EOF' >/etc/sysctl.d/30-ip_forward.conf
net.ipv4.ip_forward=1
net.ipv4.conf.eth0.send_redirects=0
net.ipv4.ip_forward_use_pmtu=1
EOF

# reload config
sysctl --load /etc/sysctl.d/30-ip_forward.conf
sysctl -a | grep net.ipv4.ip_forward

# step 2, deploy NAT service utility
#
interface_name=$(ip route show | grep 'default' | xargs | rev | cut -d ' ' -f 1 | rev)
[[ ! -d /opt/nat/ ]] && mkdir -p /opt/nat/

cat <<EOF >/opt/nat/ip_nat.sh
#!/bin/bash

# enable ip nat postrouting via iptables command
iptables -t nat -A POSTROUTING -o ${interface_name} -j MASQUERADE

# display the NAT routing rule information
iptables -t nat -L POSTROUTING
EOF
chmod +x /opt/nat/ip_nat.sh

# step 3, configure snat service
#
cat <<EOF >/etc/systemd/system/snat.service
[Unit]
Description = SNAT via ENI ${interface_name}

[Service]
ExecStart = /opt/nat/ip_nat.sh
Type = oneshot

[Install]
WantedBy = multi-user.target
EOF

# step 4, install and enable the snat service
#
systemctl enable snat
systemctl start snat
