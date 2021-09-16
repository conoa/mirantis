#!/bin/bash

# Current host: ucp2


export PRIMARY_IP=$(hostname -I | cut -d' ' -f1)
export PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
export PRIVATE_DNS=$(curl -s http://169.254.169.254/latest/meta-data/hostname);
echo "Primary IP: $PRIMARY_IP, Public DNS: $PUBLIC_DNS, Private DNS: $PRIVATE_DNS";

docker container run --rm -it --name ucp --volume /var/run/docker.sock:/var/run/docker.sock mirantis/ucp:3.4.5 id; 

docker container run --rm -it --name ucp \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    mirantis/ucp:3.4.5 uninstall-ucp --debug -i 
    
docker container run --rm -it --name ucp \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    mirantis/dtr:2.9.4 remove \
  --ucp-username admin \
  --ucp-password password \
  --ucp-url https://${PUBLIC_DNS} \
  --ucp-insecure-tls;

docker rm -f $(docker ps -aq);
docker swarm leave --force;

# Restore UCP from backup
# https://docs.mirantis.com/mke/3.3/cli-ref/mke-cli-restore.html

# If restore is performed on a different cluster than the one where the backup file was taken on, 
# the Cluster Root CA of the old MKE installation will not be restored

# Remote ucp-agent
docker service rm  $(docker service ls -q)

# Mistake 1: https://ucp2-dns
docker container run \
  --rm \
  --interactive \
  --name ucp \
  --volume /var/run/docker.sock:/var/run/docker.sock  \
   mirantis/ucp:3.4.5 restore --force-minimums --san ucp2-dns < cluster-1-ucp-backup.tar
 
openssl s_client -showcerts -connect ucp2-dns/_ping:443 < /dev/null | openssl x509 -outform DER > derp.der

curl -v -k https://ucp2-dns/_ping

# Restore DTR from backup
# https://docs.mirantis.com/containers/v3.0/dockeree-products/msr/msr-admin/disaster-recovery/restore-from-backup.html

docker run -i --rm \
  --env UCP_PASSWORD=password \
  mirantis/dtr:2.9.4 restore \
  --debug \
  --ucp-url https://ucp2-dns \
  --ucp-insecure-tls \
  --ucp-username admin \
  --ucp-node ip-172-31-2-202.eu-north-1.compute.internal \
  --replica-id 51147576cb75 \
  --dtr-storage-volume images \
  --dtr-external-url https://dtr2-dns < cluster-1-dtr-backup.tar


