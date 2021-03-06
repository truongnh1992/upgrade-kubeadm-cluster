# Upgrading kubeadm HA cluster from v1.13.5 to v1.14.0

### Deploying multi-master nodes (High Availability) K8S
1. Follow the tutorial guide at: https://vietkubers.github.io/2019-01-31-ha-cluster-with-kubeadm.html
2. The result:

```console
master1@k8s-master1:~$ sudo kubectl get node -o wide
NAME          STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8s-master1   Ready    master   20h   v1.13.5   10.164.178.161   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-master2   Ready    master   19h   v1.13.5   10.164.178.162   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-master3   Ready    master   19h   v1.13.5   10.164.178.163   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-worker1   Ready    <none>   19h   v1.13.5   10.164.178.233   <none>        Ubuntu 16.04.6 LTS   4.4.0-148-generic   docker://18.9.2
k8s-worker2   Ready    <none>   19h   v1.13.5   10.164.178.234   <none>        Ubuntu 16.04.6 LTS   4.4.0-148-generic   docker://18.9.2
k8s-worker3   Ready    <none>   19h   v1.13.5   10.164.178.235   <none>        Ubuntu 16.04.6 LTS   4.4.0-148-generic   docker://18.9.2
```

### Upgrading the first control plane node (master 1)
1. Find the version to upgrade to
```console
sudo apt update
sudo apt-cache policy kubeadm
```

2. Upgrade the control plane (master) node
```console
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt upgrade
sudo apt-get install kubeadm=1.14.0-00
sudo apt-mark hold kubeadm
```

3. Verify that the download works and has the expected version
```console
sudo kubeadm version
```

4. Modify `configmap/kubeadm-config` for this control plane node
```console
kubectl edit configmap -n kube-system kubeadm-config
```
<details>
  <summary>Click here to see yaml file</summary>
  
```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  ClusterConfiguration: |
    apiServer:
      certSANs:
      - 10.164.178.238
      extraArgs:
        authorization-mode: Node,RBAC
      timeoutForControlPlane: 4m0s
    apiVersion: kubeadm.k8s.io/v1beta1
    certificatesDir: /etc/kubernetes/pki
    clusterName: kubernetes
    controlPlaneEndpoint: 10.164.178.238:6443
    controllerManager: {}
    dns:
      type: CoreDNS
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: k8s.gcr.io
    kind: ClusterConfiguration
    kubernetesVersion: v1.14.0
    networking:
      dnsDomain: cluster.local
      podSubnet: ""
      serviceSubnet: 10.96.0.0/12
    scheduler: {}
  ClusterStatus: |
    apiEndpoints:
      k8s-master1:
        advertiseAddress: 10.164.178.161
        bindPort: 6443
      k8s-master2:
        advertiseAddress: 10.164.178.162
        bindPort: 6443
      k8s-master3:
        advertiseAddress: 10.164.178.163
        bindPort: 6443
    apiVersion: kubeadm.k8s.io/v1beta1
    kind: ClusterStatus
kind: ConfigMap
metadata:
  creationTimestamp: "2019-05-21T10:08:03Z"
  name: kubeadm-config
  namespace: kube-system
  resourceVersion: "209870"
  selfLink: /api/v1/namespaces/kube-system/configmaps/kubeadm-config
  uid: 52419642-7bb0-11e9-8a89-0800270fde1d
```
</details>

5. Remove the `etcd` section completely

6. Upgrade the `kubelet` and `kubectl`
```console
sudo apt-mark unhold kubelet
sudo apt-get install kubelet=1.14.0-00 kubectl=1.14.0-00
sudo systemctl restart kubelet
```

7. Start the upgrade
```console
sudo kubeadm upgrade apply v1.14.0
```

<details>
  <summary>The result:</summary>
  
```
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade/version] You have chosen to change the cluster version to "v1.14.0"
[upgrade/versions] Cluster version: v1.13.5
[upgrade/versions] kubeadm version: v1.14.0
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
[upgrade/prepull] Will prepull images for components [kube-apiserver kube-controller-manager kube-scheduler etcd]
[upgrade/prepull] Prepulling image for component etcd.
[upgrade/prepull] Prepulling image for component kube-controller-manager.
[upgrade/prepull] Prepulling image for component kube-scheduler.
[upgrade/prepull] Prepulling image for component kube-apiserver.
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-etcd
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Prepulled image for component kube-scheduler.
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Successfully prepulled the images for all the control plane components
[upgrade/apply] Upgrading your Static Pod-hosted control plane to version "v1.14.0"...
Static pod: kube-apiserver-k8s-master1 hash: 0bfe0e23146541c7790c4cecc43bff62
Static pod: kube-controller-manager-k8s-master1 hash: 0d778e323727eb1c5a1e6a163de25378
Static pod: kube-scheduler-k8s-master1 hash: 15c129447b0aa0f760fe2d7ba217ecd4
[upgrade/etcd] Upgrading to TLS for etcd
Static pod: etcd-k8s-master1 hash: 0dff236341700eb87440ef785044a2db
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/etcd.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-19-16/etcd.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: etcd-k8s-master1 hash: 0dff236341700eb87440ef785044a2db
Static pod: etcd-k8s-master1 hash: 2b40ab1577fdf88e9492c4efad745072
[apiclient] Found 3 Pods for label selector component=etcd
[upgrade/staticpods] Component "etcd" upgraded successfully!
[upgrade/etcd] Waiting for etcd to become available
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests910084113"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-19-16/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master1 hash: 6f6c300e316783259892ea19cae1e5a1
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-19-16/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master1 hash: 0d778e323727eb1c5a1e6a163de25378
Static pod: kube-controller-manager-k8s-master1 hash: 02df4763b3483e61954cef50c0eb08e5
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-19-16/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master1 hash: 15c129447b0aa0f760fe2d7ba217ecd4
Static pod: kube-scheduler-k8s-master1 hash: 99889e63c907d2d88bde0d0ad2e0df05
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upload-config] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.14" in namespace kube-system with the configuration for the kubelets in the cluster
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.14" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.14.0". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```
</details>

### Upgrading additional control plane nodes (Master 2 and Master 3)

1. Find the version to upgrade to
```console
sudo apt update
sudo apt-cache policy kubeadm
```

2. Upgrade `kubeadm`
```console
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt upgrade
sudo apt-get install kubeadm=1.14.0-00
sudo apt-mark hold kubeadm
```

3. Verify that the download works and has the expected version
```console
sudo kubeadm version
```

4. Upgrade the `kubelet` and `kubectl`
```console
sudo apt-mark unhold kubelet
sudo apt-get install kubelet=1.14.0-00 kubectl=1.14.0-00
sudo systemctl restart kubelet
```

5. Start the upgrade
```console
master2@k8s-master2:~$ sudo kubeadm upgrade node experimental-control-plane
```
<details>
  <summary>The result:</summary>
  
```
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.14.0"...
Static pod: kube-apiserver-k8s-master2 hash: ba03afd84d454d318c2cc6e3a6e23f53
Static pod: kube-controller-manager-k8s-master2 hash: 0a9f25af4e4ad5e5427feb8295fc055a
Static pod: kube-scheduler-k8s-master2 hash: 8cea5badbe1b177ab58353a73cdedd01
[upgrade/etcd] Upgrading to TLS for etcd
Static pod: etcd-k8s-master2 hash: d990ad5b88743835159168644453f90b
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/etcd.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-45-09/etcd.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: etcd-k8s-master2 hash: d990ad5b88743835159168644453f90b
Static pod: etcd-k8s-master2 hash: e56ee6ac7c0de512a17ef30c3a44e01c
[apiclient] Found 3 Pods for label selector component=etcd
[upgrade/staticpods] Component "etcd" upgraded successfully!
[upgrade/etcd] Waiting for etcd to become available
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests998233672"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-45-09/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master2 hash: ba03afd84d454d318c2cc6e3a6e23f53
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-45-09/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master2 hash: 0a9f25af4e4ad5e5427feb8295fc055a
Static pod: kube-controller-manager-k8s-master2 hash: e45f10af1ae684722cbd74cb11807900
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-45-09/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master2 hash: 8cea5badbe1b177ab58353a73cdedd01
Static pod: kube-scheduler-k8s-master2 hash: 58272442e226c838b193bbba4c44091e
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upgrade] The control plane instance for this node was successfully updated!
```
</details>

```console
master3@k8s-master3:~$ sudo kubeadm upgrade node experimental-control-plane
```
<details>
  <summary>The result:</summary>
  
```
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.14.0"...
Static pod: kube-apiserver-k8s-master3 hash: 556e7d43da7a389c6b0b116ae5a46d97
Static pod: kube-controller-manager-k8s-master3 hash: 0a9f25af4e4ad5e5427feb8295fc055a
Static pod: kube-scheduler-k8s-master3 hash: 8cea5badbe1b177ab58353a73cdedd01
[upgrade/etcd] Upgrading to TLS for etcd
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests859456185"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-48-13/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master3 hash: 556e7d43da7a389c6b0b116ae5a46d97
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-48-13/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master3 hash: 0a9f25af4e4ad5e5427feb8295fc055a
Static pod: kube-controller-manager-k8s-master3 hash: e45f10af1ae684722cbd74cb11807900
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-21-23-48-13/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master3 hash: 8cea5badbe1b177ab58353a73cdedd01
Static pod: kube-scheduler-k8s-master3 hash: 58272442e226c838b193bbba4c44091e
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upgrade] The control plane instance for this node was successfully updated!
```
</details>

### Upgrading worker nodes (worker 1, worker 2 and worker 3)

1. Upgrade `kubeadm` on all worker nodes
```console
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt upgrade
sudo apt-get install kubeadm=1.14.0-00
sudo apt-mark hold kubeadm
```

2. Cordon the worker node, on the **Master node**, run:
```console
sudo kubectl drain $WORKERNODE --ignore-daemonsets
```
3. Upgrade the `kubelet` config on **worker nodes**
```console
sudo kubeadm upgrade node config --kubelet-version v1.14.0
```
4. Upgrade `kubelet` and `kubectl`
```console
sudo apt update && sudo apt upgrade
sudo apt-get install kubelet=1.14.0-00 kubectl=1.14.0-00
sudo systemctl restart kubelet
```
5. Uncordon the worker nodes, bring the node back online by marking it scheduable
```console
sudo kubectl uncordon $WORKERNODE
```
## Verify the status of cluster
```console
master1@k8s-master1:~$ sudo kubectl get node
NAME          STATUS   ROLES    AGE   VERSION
k8s-master1   Ready    master   21h   v1.14.0
k8s-master2   Ready    master   21h   v1.14.0
k8s-master3   Ready    master   21h   v1.14.0
k8s-worker1   Ready    <none>   20h   v1.14.0
k8s-worker2   Ready    <none>   20h   v1.14.0
k8s-worker3   Ready    <none>   20h   v1.14.0
```
