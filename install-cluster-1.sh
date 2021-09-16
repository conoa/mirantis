#!/bin/bash

# Current host: ucp1

export PRIMARY_IP=$(hostname -I | cut -d' ' -f1)
export PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
export PRIVATE_DNS=$(curl -s http://169.254.169.254/latest/meta-data/hostname);
echo "Primary IP: $PRIMARY_IP, Public DNS: $PUBLIC_DNS, Private DNS: $PRIVATE_DNS";

docker container run --rm -it --name ucp --volume /var/run/docker.sock:/var/run/docker.sock mirantis/ucp:3.4.5 id; 

docker container run --rm -it --name ucp \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    mirantis/ucp:3.4.5 uninstall-ucp --id nul1y34c8q9w21vnto7o8mzxj;

docker rm -f $(docker ps -aq);
docker swarm leave --force;

docker container run --rm -it --name ucp \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    mirantis/ucp:3.4.5 install \
    --host-address ${PRIMARY_IP} \
    --force-minimums --pod-cidr 10.0.0.0/16 \
    --san ${PUBLIC_DNS} --san ${PRIVATE_DNS} \
    --admin-username admin \
    --admin-password password;

docker run -it --rm \
  -v /tmp:/tmp --entrypoint=/bin/sh \
  mcassel/dtr:2.9.4

docker run -it --rm \
  -v /tmp:/tmp \
  mcassel/dtr:2.9.4 install \
  --dtr-external-url https://dtr1-dns  \
  --ucp-node ip-172-31-34-15.eu-north-1.compute.internal \
  --ucp-username admin \
  --ucp-password password \
  --ucp-url https://https://ucp1-dns \
  --ucp-insecure-tls;
  
# Backup ucp

docker run --rm -i \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --log-driver none \
        mirantis/ucp:3.4.5 \
        backup --no-passphrase --debug > cluster-1-ucp-backup.tar

tar tvf cluster-1-ucp-backup.tar

sudo openssl x509 -in /var/lib/docker/volumes/ucp-controller-server-certs/_data/cert.pem -text -noout

# Backup dtr

docker run -i --rm mirantis/dtr:2.9.4 \
    backup --debug \
    --ucp-url https://https://ucp1-dns \
    --ucp-username admin \
    --ucp-password password \
    --ucp-insecure-tls > cluster-1-dtr-backup.tar;

tar tvf cluster-1-dtr-backup.tar

# Copy backups to laptop
scp -i aws.pem  ubuntu@https://ucp1-dns:~/cluster-1-ucp-backup.tar .
scp -i aws.pem  ubuntu@https://ucp1-dns:~/cluster-1-dtr-backup.tar .

scp -i aws.pem  cluster-1-ucp-backup.tar ubuntu@ucp2-dns:~
scp -i aws.pem  cluster-1-dtr-backup.tar ubuntu@ucp2-dns:~

# Appendix

tar tvf cluster-1-ucp-backup.tar 
-rw-r--r-- 0/0            8378 1970-01-01 00:00 ./ucp-auth-store.json
-rw-r--r-- 0/0           14508 1970-01-01 00:00 ./ucp-kube-apiserver.json
-rw-r--r-- 0/0           10545 1970-01-01 00:00 ./ucp-kube-controller-manager.json
-rw-r--r-- 0/0            7252 1970-01-01 00:00 ./ucp-kubelet.json
-rw-r--r-- 0/0            7505 1970-01-01 00:00 ./ucp-kube-proxy.json
-rw-r--r-- 0/0            9439 1970-01-01 00:00 ./ucp-kube-scheduler.json
-rw-r--r-- 0/0           10701 1970-01-01 00:00 ./ucp-controller.json
-rw-r--r-- 0/0            8952 1970-01-01 00:00 ./ucp-swarm-manager.json
-rw-r--r-- 0/0           10353 1970-01-01 00:00 ./ucp-kv.json
-rw-r--r-- 0/0            8819 1970-01-01 00:00 ./ucp-proxy.json
-rw-r--r-- 0/0            8690 1970-01-01 00:00 ./ucp-client-root-ca.json
-rw-r--r-- 0/0            8694 1970-01-01 00:00 ./ucp-cluster-root-ca.json
-rw-r--r-- 0/0           11419 1970-01-01 00:00 ./ucp-manager-agent.yzx9my8y6ypycpe34bjh6ijkq.z16o0my5x83ec54yp1y2z8t8y.json
drwxr-xr-x nobody/nobody     0 2021-09-13 16:11 ./ucp-backup/1631549510183/
-rw-r--r-- nobody/nobody 13543 2021-09-13 16:11 ./ucp-backup/1631549510183/auth-store.tar.gz
-rw------- nobody/nobody 5574688 2021-09-13 16:11 ./ucp-backup/1631549510183/etcd.backup.db
drwxr-xr-x root/root           0 2021-09-13 10:30 ./ucp-client-root-ca/
-rw-r--r-- root/root         579 2021-09-13 10:30 ./ucp-client-root-ca/cert.pem
-rw------- root/root         227 2021-09-13 10:30 ./ucp-client-root-ca/key.pem
drwxr-xr-x root/root           0 2021-09-13 10:30 ./ucp-cluster-root-ca/
-rw-r--r-- root/root         550 2021-09-13 10:30 ./ucp-cluster-root-ca/cert.pem
-rw------- root/root         227 2021-09-13 10:30 ./ucp-cluster-root-ca/key.pem
drwxr-xr-x root/root           0 2021-09-13 10:31 ./ucp-controller-server-certs/
-rw-r--r-- nobody/nobody     579 2021-09-13 10:31 ./ucp-controller-server-certs/ca.pem
-rw-r--r-- nobody/nobody    1635 2021-09-13 10:31 ./ucp-controller-server-certs/cert.pem
-rw-r--r-- nobody/nobody       0 2021-09-13 10:31 ./ucp-controller-server-certs/client_ca.pem
-rw------- nobody/nobody    2459 2021-09-13 10:31 ./ucp-controller-server-certs/key.pem


tar tvf cluster-1-dtr-backup.tar
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/client_tokens/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/poll_mirroring_policies/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/promotion_policies/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/content_caches/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/webhooks/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/tags/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/events/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/manifests/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/scanned_layers/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/layer_vuln_overrides/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/changefeed/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/scanned_images/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/blob_links/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/namespace_team_access/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/tuf_files/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/properties/
-rw------- 0/0             613 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/0
-rw------- 0/0             614 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/1
-rw------- 0/0             319 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/2
-rw------- 0/0              75 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/3
-rw------- 0/0             309 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/4
-rw------- 0/0             745 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/5
-rw------- 0/0             677 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/6
-rw------- 0/0             313 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/7
-rw------- 0/0             620 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/8
-rw------- 0/0             316 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/9
-rw------- 0/0             624 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/10
-rw------- 0/0             676 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/11
-rw------- 0/0             326 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/12
-rw------- 0/0             679 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/13
-rw------- 0/0             310 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/14
-rw------- 0/0             314 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/15
-rw------- 0/0             336 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/16
-rw------- 0/0             758 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/17
-rw------- 0/0             336 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/18
-rw------- 0/0             686 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/19
-rw------- 0/0             312 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/20
-rw------- 0/0             329 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/21
-rw------- 0/0             780 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/22
-rw------- 0/0             318 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/23
-rw------- 0/0             323 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/24
-rw------- 0/0             686 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/25
-rw------- 0/0             331 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/26
-rw------- 0/0             681 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/27
-rw------- 0/0             320 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/28
-rw------- 0/0             687 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/29
-rw------- 0/0             619 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/30
-rw------- 0/0             106 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/31
-rw------- 0/0             331 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/32
-rw------- 0/0             693 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/33
-rw------- 0/0             681 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/34
-rw------- 0/0            4329 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/35
-rw------- 0/0             323 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/36
-rw------- 0/0             319 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/37
-rw------- 0/0             318 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/38
-rw------- 0/0            2684 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/39
-rw------- 0/0             263 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/40
-rw------- 0/0             764 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/41
-rw------- 0/0              78 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/42
-rw------- 0/0             140 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/43
-rw------- 0/0             785 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/44
-rw------- 0/0             314 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/45
-rw------- 0/0              94 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/46
-rw------- 0/0           12212 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/47
-rw------- 0/0              73 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/48
-rw------- 0/0             785 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/49
-rw------- 0/0              88 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/50
-rw------- 0/0              78 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/51
-rw------- 0/0             937 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/properties/52
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/helm_charts/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/pruning_policies/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/repository_team_access/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/push_mirroring_policies/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/repositories/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/user_settings/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/metrics/
-rw------- 0/0              38 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/metrics/0
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/blobs/
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/crons/
-rw------- 0/0             180 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/crons/0
-rw------- 0/0             174 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/crons/1
-rw------- 0/0             176 2021-09-13 16:12 dtr-backup-v2.9.4-online/rethink/crons/2
drwx------ 0/0               0 1970-01-01 00:00 dtr-backup-v2.9.4-online/rethink/private_keys/
