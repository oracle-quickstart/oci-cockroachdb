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

# Install OCI CLI
curl -L -O https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
sh install.sh --accept-all-defaults

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
    cockroach$i.cockroach.cockroach.oraclevcn.com \
    localhost \
    127.0.0.1 \
    ${lbIP} \
    --certs-dir=certs \
    --ca-key=my-safe-directory/ca.key
    cp certs/node.crt certs-cockroach$i/node.crt
    cp certs/node.key certs-cockroach$i/node.key
    curl -X PUT --data-binary @certs/ca.crt https://objectstorage.${region}.oraclecloud.com${par_request_url}ca$i.crt
    curl -X PUT --data-binary @certs-cockroach$i/node.crt https://objectstorage.${region}.oraclecloud.com${par_request_url}node$i.crt
    curl -X PUT --data-binary @certs-cockroach$i/node.key https://objectstorage.${region}.oraclecloud.com${par_request_url}node$i.key
    rm certs/node.crt certs/node.key
    done
    cp certs/ca.crt certs-cockroach0/ca.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/ca0.crt > ~/certs/node.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/node0.key > ~/certs/node.key
    cockroach cert create-client root --certs-dir=certs-cockroach0 --ca-key=my-safe-directory/ca.key
else
    mkdir ~/certs
    nodeNumber=$(echo -n $(hostname) | tail -c 1)
    while ! [ -s ~/certs/ca.crt ] && ! [ -s ~/certs/node.crt ] && ! [ -s ~/certs/node.key ]; do
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/ca$nodeNumber.crt > ~/certs/ca.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/node$nodeNumber.crt > ~/certs/node.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/node$nodeNumber.key > ~/certs/node.key
    sleep 5
    done
fi

## Start and initialize the cluster
if [[ $initDNS == $nodeDNS ]]
then
    chmod 600 certs-cockroach0/node.key
    cockroach start --certs-dir=certs-cockroach0 --advertise-addr=$initDNS --join=$join --cache=.25 --max-sql-memory=.25 --background
    cockroach init --certs-dir=certs-cockroach0 --host=$initDNS
else
    until $(curl --output /dev/null --silent --head --fail http://${name}0:8080); do
    sleep 5
    done
    chmod 600 certs/node.key
    cockroach start --certs-dir=certs --advertise-addr=$nodeDNS --join=$join --cache=.25 --max-sql-memory=.25 --background
fi