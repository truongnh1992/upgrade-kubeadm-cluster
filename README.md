# upgrade-kubeadm-cluster
The way to upgrade K8S cluster created with **kubeadm** from version 1.13.0 to 1.14.0

# 1. Find the version to upgrade to
```sh
sudo apt update
sudo apt-cache policy kubeadm
```

# 2. Upgrade the control plane (master) node
```sh
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt upgrade
sudo apt-get install kubeadm=1.14.0-00
sudo apt-mark hold kubeadm
```

Verify that the download works and has the expected version:
```sh
sudo kubeadm version
```

Apply the upgrade by executing the following command:
```sh
sudo kubeadm upgrade apply v1.14.0
```

# 3. Upgrade the kubelet and kubectl on the control plane (master) node
```sh
sudo apt-mark unhold kubelet
sudo apt update && sudo apt upgrade
sudo apt-get install kubelet=1.14.0-00 kubectl=1.14.0-00
```

Restart the **kubelet**
```sh
sudo systemctl restart kubelet
```

# 4. Upgrade worker nodes

Upgrade kubeadm on all worker nodes:
```sh
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt upgrade
sudo apt-get install kubeadm=1.14.0-00
sudo apt-mark hold kubeadm
```

Cordon the node, on the **Master node**, run:
```sh
sudo kubectl drain $NODE --ignore-daemonsets
```
Output:
```
node/worker-node cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-flannel-ds-amd64-s8j5k, kube-system/kube-proxy-whc6q
evicting pod "coredns-fb8b8dccf-jhlgr"
evicting pod "test-ru-jz5df"
pod/coredns-fb8b8dccf-jhlgr evicted
pod/test-ru-jz5df evicted
node/worker-node evicted
```

Upgrade the kubelet config on **worker node**
```sh
sudo kubeadm upgrade node config --kubelet-version v1.14.0
```

Upgrade kubelet and kubectl
```sh
sudo apt update && sudo apt upgrade
sudo apt-get install kubelet=1.14.0-00 kubectl=1.14.0-00
```
Restart the kubelet
```sh
sudo systemctl restart kubelet
```
Uncordon the node, bring the node back online by marking it scheduable
```sh
sudo kubectl uncordon $NODE
```
# Verify the status of the cluser
```sh
sudo kubectl get nodes
```
The result:
```
NAME          STATUS   ROLES    AGE    VERSION
cncf          Ready    master   172m   v1.14.0
worker-node   Ready    <none>   169m   v1.14.0
```
