#!/bin/bash

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

# Generate certificates
n=${count}
if [[ $initDNS == $nodeDNS ]]
then
  mkdir my-safe-directory
  mkdir certs
  cockroach cert create-ca --certs-dir=certs --ca-key=my-safe-directory/ca.key
  for i in $(seq 0 $(($n > 0? $n-1: 0))); do
    mkdir certs-cockroach$i
    cockroach cert create-node \
    $(hostname -i) \
    $(hostname) \
    $(hostname -f) \
    localhost \
    127.0.0.1 \
    $lbIP \
    --certs-dir=certs \
    --ca-key=my-safe-directory/ca.key
    curl -X PUT -d 'certs/ca.crt' -v https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/ca$i.crt
    curl -X PUT -d 'certs/node.crt' -v https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/node$i.crt
    curl -X PUT -d 'certs/node.key' -v https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/node$i.key
    rm certs/node.crt certs/node.key
    done
    curl https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/node0.crt > ~/certs/node.crt
    curl https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/node$0.key > ~/certs/node.key
else
    mkdir ~/certs
    nodeNumber=$(echo -n $(hostname) | tail -c 1)
    while ! [ -s ~/certs/ca.crt ] && ! [ -s ~/certs/node.crt ] && ! [ -s ~/certs/node.key ]; do
    curl https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/ca$nodeNumber.crt > ~/certs/ca.crt
    curl https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/node$nodeNumber.crt > ~/certs/node.crt
    curl https://objectstorage.us-ashburn-1.oraclecloud.com/p/J-P2KZLzsALGMi52Js11xBE7FvlzxNYvvYFndhd_GbQ/n/partners/b/cockroach-OCOIWK/o/node$nodeNumber.key > ~/certs/node.key
    sleep 5
    done
fi

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