Installing kubeadm v1.13.0 cluster
======================================

## 1. Preparing Environment

OS: Ubuntu 16.04 LTS

**Master Node:**

    enp0s3: NAT (Access to Internet)
    enp0s8:
        Host Only
        192.168.1.55 (Master Node IP)

**Worker Node:**

    enp0s3: NAT (Access to Internet)
    enp0s8:
        Host Only
        192.168.1.66 (Worker Node IP)

***Configure static IP for enp0s8 interface***
```sh
# The primary network interface
auto enp0s3
iface enp0s3 inet dhcp


auto enp0s8
iface enp0s8 inet static
address 192.168.1.55
netmask 255.255.255.0
```


### Configuring proxy for apt
```sh
sudo vim /etc/apt/apt.conf

Acquire::http::proxy "http://[Proxy_Server]:[Proxy_Port]/";
Acquire::HTTP::proxy "http://[Proxy_Server]:[Proxy_Port]/";
```

### Configuring proxy for docker
```sh
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo vim /etc/systemd/system/docker.service.d/http-proxy.conf

[Service]
Environment="HTTP_PROXY=http://[Proxy_Server]:[Proxy_Port]/"
```

## 2. Installing and deploying

### Adding kubernetes repo
```sh
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
sudo mv ~/kubernetes.list /etc/apt/sources.list.d
sudo apt-get update
```

### Installing docker kubelet kubeadm kubectl kubernetes-cni for each node
```sh
sudo apt-get install -qy docker.io kubelet=1.13.0-00 kubectl=1.13.0-00 kubeadm=1.13.0-00 \
kubernetes-cni=0.6.0-00 --allow-unauthenticated
```

### Deploying Master node (In case of using flannel overlay network)
```sh
sudo kubeadm init --apiserver-advertise-address=<PRIVATE-MASTER-IP> --pod-network-cidr=10.244.0.0/16
```

### Applying a pods network
```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
```

### Joining worker node to the cluster
```sh
sudo kubeadm join <PRIVATE-MASTER-IP>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

## 3. The result
```sh
sudo kubectl get nodes

NAME          STATUS   ROLES    AGE    VERSION
master-node   Ready    master   2d1h   v1.13.0
worker-node   Ready    <none>   27m    v1.13.0
```
