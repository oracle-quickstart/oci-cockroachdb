#!/bin/bash

# Log everything to log.out
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log.out 2>&1

# Create the list of nodes to join the cluster based on the number of instances
initDNS="${name}0.${name}.${name}.oraclevcn.com"
nodeDNS=$(hostname -f)

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
    # Upload certificates to OCI Object Storage
    curl -X PUT --data-binary @certs/ca.crt https://objectstorage.${region}.oraclecloud.com${par_request_url}ca$i.crt
    curl -X PUT --data-binary @certs-cockroach$i/node.crt https://objectstorage.${region}.oraclecloud.com${par_request_url}node$i.crt
    curl -X PUT --data-binary @certs-cockroach$i/node.key https://objectstorage.${region}.oraclecloud.com${par_request_url}node$i.key
    rm certs/node.crt certs/node.key
    done
    cp certs/ca.crt certs-cockroach0/ca.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/ca0.crt > /certs/node.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/node0.key > /certs/node.key
    cockroach cert create-client root --certs-dir=certs-cockroach0 --ca-key=my-safe-directory/ca.key
    # Add certificate to load balancer backends and listeners
    cat << EOF > certs-cockroach0/lb-bes1
    [
      {
        "backup": false,
        "drain": false,
        "ip-address": "10.0.1.6",
        "offline": false,
        "port": 26257,
        "weight": 1
      },
      {
        "backup": false,
        "drain": false,
        "ip-address": "10.0.1.5",
        "offline": false,
        "port": 26257,
        "weight": 1
      },
      {
        "backup": false,
        "drain": false,
        "ip-address": "10.0.1.4",
        "offline": false,
        "port": 26257,
        "weight": 1
      }
    ]
EOF
    cat << EOF > certs-cockroach0/lb-bes2
    [
      {
        "backup": false,
        "drain": false,
        "ip-address": "10.0.1.6",
        "offline": false,
        "port": 8080,
        "weight": 1
      },
      {
        "backup": false,
        "drain": false,
        "ip-address": "10.0.1.4",
        "offline": false,
        "port": 8080,
        "weight": 1
      },
      {
        "backup": false,
        "drain": false,
        "ip-address": "10.0.1.5",
        "offline": false,
        "port": 8080,
        "weight": 1
      }
    ]
EOF
/root/bin/oci lb certificate create --certificate-name cockroachcert --load-balancer-id ${lbID} --ca-certificate-file certs-cockroach0/ca.crt --private-key-file certs-cockroach0/node.key --public-certificate-file certs-cockroach0/node.crt --wait-for-state SUCCEEDED --auth instance_principal
/root/bin/oci lb listener update --default-backend-set-name lb-bes1 --listener-name tcp26257 --load-balancer-id ${lbID} --port 26257 --protocol TCP --ssl-certificate-name cockroachcert --force --wait-for-state SUCCEEDED --auth instance_principal
/root/bin/oci lb listener update --default-backend-set-name lb-bes2 --listener-name http8080 --load-balancer-id ${lbID} --port 8080 --protocol HTTP --ssl-certificate-name cockroachcert --force --wait-for-state SUCCEEDED --auth instance_principal
/root/bin/oci lb backend-set update --backend-set-name lb-bes1 --load-balancer-id ${lbID} --backends file://certs-cockroach0/lb-bes1 --health-checker-protocol HTTP --health-checker-url-path /health?ready=1 --policy ROUND_ROBIN --ssl-certificate-name cockroachcert --force --wait-for-state SUCCEEDED --auth instance_principal
/root/bin/oci lb backend-set update --backend-set-name lb-bes2 --load-balancer-id ${lbID} --backends file://certs-cockroach0/lb-bes2 --health-checker-protocol HTTP --health-checker-url-path /health?ready=1 --policy ROUND_ROBIN --ssl-certificate-name cockroachcert --force --wait-for-state SUCCEEDED --auth instance_principal
sleep 60
/root/bin/oci os object bulk-delete -ns ${namespace} --bucket-name ${bucket} --force --auth instance_principal
else
    mkdir /certs
    nodeNumber=$(echo -n $(hostname) | tail -c 1)
    while ! [ -s ~/certs/ca.crt ] && ! [ -s ~/certs/node.crt ] && ! [ -s ~/certs/node.key ]; do
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/ca$nodeNumber.crt > /certs/ca.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/node$nodeNumber.crt > /certs/node.crt
    curl https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/node$nodeNumber.key > /certs/node.key
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