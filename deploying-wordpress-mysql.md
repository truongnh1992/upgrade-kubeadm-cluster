# Deploying Stateful WordPress on K8s HA Cluster

## Installing and configuring NFS server

Installing and configuring a NFS server on Linux machine.

```console
sudo apt-get install nfs-kernel-server
sudo mkdir -p /opt/data
sudo chmod -R 777 /opt/data
sudo chown -R  nobody:nogroup /opt/data
```
```console
sudo vim /etc/exports
/opt/data *(rw,sync,no_root_squash,fsid=0,no_subtree_check)
```
```console
sudo exportfs -a 
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl start rpcbind
sudo systemctl start nfs-server

sudo mkdir -p /opt/data/vol/{0,1,2}
sudo mkdir -p /opt/data/content
```

## Auto-mounting NFS at boot-time

In each worker node, running the below commands.

```console
sudo apt install nfs-common nfs-kernel-server
sudo systemctl start rpcbind nfs-mountd
sudo systemctl enable rpcbind nfs-mountd
```
```console
sudo vim /etc/fstab
10.164.178.238:/opt/data        /mnt/data       nfs     rw,sync,hard,intr       0       0
```
```console
sudo apt install autofs
```
```console
sudo vim /etc/auto.master
/-    /etc/auto.mount
```
```console
sudo vim /etc/auto.mount
/mnt/data -fstype=nfs,rw  10.164.178.238:/opt/data
```
```console
sudo systemctl start autofs
sudo systemctl enable autofs
sudo /lib/systemd/systemd-sysv-install enable autofs
```
