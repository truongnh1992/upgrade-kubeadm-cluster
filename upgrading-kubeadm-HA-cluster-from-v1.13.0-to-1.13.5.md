# Upgrading kubeadm HA cluster from v1.13.0 to v1.13.5 (stacked etcd)

### Deploying multi-master nodes (High Availability) K8S
1. Follow the tutorial guide at: https://vietkubers.github.io/2019-01-31-ha-cluster-with-kubeadm.html
2. The result:

![nodes](https://vietkubers.github.io/static/img/multi-master-ha/nodess.PNG)

### Upgrading the first control plane node (master 1)
1. Find the version to upgrade to
```sh
sudo apt update
sudo apt-cache policy kubeadm
```

2. Upgrade the control plane (master) node
```sh
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt upgrade
sudo apt-get install kubeadm=1.13.5-00
sudo apt-mark hold kubeadm
```

3. Verify that the download works and has the expected version
```sh
sudo kubeadm version
```

4. Modify `configmap/kubeadm-config` for this control plane node
```sh
kubectl edit configmap -n kube-system kubeadm-config
```
5. Remove the `etcd` section completely

6. Start the upgrade
```sh
sudo kubeadm upgrade apply v1.13.5
```

### Upgrading additional control plane nodes
Start the upgrade
```sh
sudo kubeadm upgrade node experimental-control-plane
```
