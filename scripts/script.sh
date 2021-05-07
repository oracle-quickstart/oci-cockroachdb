#!/bin/bash

cp /home/opc/.ssh/authorized_keys /home/opc/.ssh/authorized_keys.bak
echo "${ssh_public_key}" >> /home/opc/.ssh/authorized_keys
chown -R opc /home/opc/.ssh/authorized_keys

initDNS="${name}0.${name}.${name}.oraclevcn.com"
nodeDNS=$(hostname -f)

# Create the list of nodes to join the cluster based on the number of instances
n=${count}
join=""

for i in $(seq 0 $(($n > 0? $n-1: 0))); do 
  nodes="${name}$i.${name}.${name}.oraclevcn.com"
  join="$${join}$${join:+,}$nodes"
done

# Set firewall rules
firewall-offline-cmd --add-port=26257/tcp
firewall-offline-cmd --add-port=8080/tcp
systemctl restart firewalld

# Download and install CockroachDB
wget -qO- https://binaries.cockroachdb.com/cockroach-v19.1.1.linux-amd64.tgz | tar  xvz
cp -i cockroach-v19.1.1.linux-amd64/cockroach /usr/local/bin

# Start and initialize the cluster
if [[ $initDNS == $nodeDNS ]]
then
    cockroach start --insecure --advertise-addr=$initDNS --join=$join --cache=.25 --max-sql-memory=.25 --background
    cockroach init --insecure --host=$initDNS
else
    until $(curl --output /dev/null --silent --head --fail http://${name}0:8080); do
    sleep 5
    done
    cockroach start --insecure --advertise-addr=$nodeDNS --join=$join --cache=.25 --max-sql-memory=.25 --background
fi