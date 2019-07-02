# Upgrading kubeadm HA cluster from v1.14.0 to v1.15.0

### Deploying multi-master nodes (High Availability) K8S
1. Follow the tutorial guide at: https://vietkubers.github.io/2019-01-31-ha-cluster-with-kubeadm.html
2. The result:

```console
master1@k8s-master1:~$ sudo kubectl get node -o wide
NAME          STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8s-master1   Ready    master   20h   v1.14.0   10.164.178.161   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-master2   Ready    master   19h   v1.14.0   10.164.178.162   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-master3   Ready    master   19h   v1.14.0   10.164.178.163   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-worker1   Ready    <none>   19h   v1.14.0   10.164.178.233   <none>        Ubuntu 16.04.6 LTS   4.4.0-148-generic   docker://18.9.2
k8s-worker2   Ready    <none>   19h   v1.14.0   10.164.178.234   <none>        Ubuntu 16.04.6 LTS   4.4.0-148-generic   docker://18.9.2
k8s-worker3   Ready    <none>   19h   v1.14.0   10.164.178.235   <none>        Ubuntu 16.04.6 LTS   4.4.0-148-generic   docker://18.9.2
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
sudo apt-get install kubeadm=1.15.0-00
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
    apiVersion: kubeadm.k8s.io/v1beta2
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
    kubernetesVersion: v1.15.0
    networking:
      dnsDomain: cluster.local
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
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: ClusterStatus
kind: ConfigMap
metadata:
  creationTimestamp: "2019-06-25T04:12:53Z"
  name: kubeadm-config
  namespace: kube-system
  resourceVersion: "1337635"
  selfLink: /api/v1/namespaces/kube-system/configmaps/kubeadm-config
  uid: 81334a15-96ff-11e9-b14f-0800270fde1d
```
</details>

5. Remove the `etcd` section completely

6. Upgrade the `kubelet` and `kubectl`
```console
sudo apt-mark unhold kubelet
sudo apt-get install kubelet=1.15.0-00 kubectl=1.15.0-00
sudo systemctl restart kubelet
```

7. Start the upgrade
```console
sudo kubeadm upgrade apply v1.15.0
```

<details>
  <summary>The result:</summary>
  
```
master1@k8s-master1:~$ sudo kubeadm upgrade apply v1.15.0
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade/version] You have chosen to change the cluster version to "v1.15.0"
[upgrade/versions] Cluster version: v1.14.0
[upgrade/versions] kubeadm version: v1.15.0
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
[upgrade/prepull] Will prepull images for components [kube-apiserver kube-controller-manager kube-scheduler etcd]
[upgrade/prepull] Prepulling image for component etcd.
[upgrade/prepull] Prepulling image for component kube-controller-manager.
[upgrade/prepull] Prepulling image for component kube-scheduler.
[upgrade/prepull] Prepulling image for component kube-apiserver.
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-etcd
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component kube-scheduler.
[upgrade/prepull] Successfully prepulled the images for all the control plane components
[upgrade/apply] Upgrading your Static Pod-hosted control plane to version "v1.15.0"...
Static pod: kube-apiserver-k8s-master1 hash: d2c5511b998c161426c93d49e7ff58f4
Static pod: kube-controller-manager-k8s-master1 hash: 277780ac9fa6de28b5878a6281e9e60b
Static pod: kube-scheduler-k8s-master1 hash: b9b98173c3f4bbf002d9b1d0d7e3328f
[upgrade/etcd] Upgrading to TLS for etcd
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests674319144"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Renewing apiserver certificate
[upgrade/staticpods] Renewing apiserver-kubelet-client certificate
[upgrade/staticpods] Renewing front-proxy-client certificate
[upgrade/staticpods] Renewing apiserver-etcd-client certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-05-59/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master1 hash: d2c5511b998c161426c93d49e7ff58f4
Static pod: kube-apiserver-k8s-master1 hash: efad0f7a5068cc704c1d44ee19ade86a
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Renewing controller-manager.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-05-59/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master1 hash: 277780ac9fa6de28b5878a6281e9e60b
Static pod: kube-controller-manager-k8s-master1 hash: b04fd97d650fff904de73189ad50fd75
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Renewing scheduler.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-05-59/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master1 hash: b9b98173c3f4bbf002d9b1d0d7e3328f
Static pod: kube-scheduler-k8s-master1 hash: 31d9ee8b7fb12e797dc981a8686f6b2b
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.15" in namespace kube-system with the configuration for the kubelets in the cluster
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.15" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.15.0". Enjoy!
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
sudo apt-get install kubeadm=1.15.0-00
sudo apt-mark hold kubeadm
```

3. Verify that the download works and has the expected version
```console
sudo kubeadm version
```

4. Upgrade the `kubelet` and `kubectl`
```console
sudo apt-mark unhold kubelet
sudo apt-get install kubelet=1.15.0-00 kubectl=1.15.0-00
sudo systemctl restart kubelet
```

5. Start the upgrade
```console
master2@k8s-master2:~$ sudo kubeadm upgrade node experimental-control-plane
```
<details>
  <summary>The result:</summary>
  
```
master2@k8s-master2:~$ sudo kubeadm upgrade node experimental-control-plane
Command "experimental-control-plane" is deprecated, this command is deprecated. Use "kubeadm upgrade node" instead
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.15.0"...
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-controller-manager-k8s-master2 hash: e45f10af1ae684722cbd74cb11807900
Static pod: kube-scheduler-k8s-master2 hash: 58272442e226c838b193bbba4c44091e
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests008229237"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-10-27/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 94e207e0d84e092ae98dc64af5b870ba
Static pod: kube-apiserver-k8s-master2 hash: 20c546712a964405dec37d87f103c95b
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[apiclient] Found 2 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-10-27/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master2 hash: 277780ac9fa6de28b5878a6281e9e60b
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[apiclient] Found 2 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-10-27/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master2 hash: b9b98173c3f4bbf002d9b1d0d7e3328f
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
master3@k8s-master3:~$ sudo kubeadm upgrade node experimental-control-plane
Command "experimental-control-plane" is deprecated, this command is deprecated. Use "kubeadm upgrade node" instead
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.15.0"...
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-controller-manager-k8s-master3 hash: e45f10af1ae684722cbd74cb11807900
Static pod: kube-scheduler-k8s-master3 hash: 58272442e226c838b193bbba4c44091e
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests182358565"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-13-35/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1a94c94ecfa9f698cfc902fc37c15be9
Static pod: kube-apiserver-k8s-master3 hash: 1de55703167e49d14bc41a2d599e4f6e
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-13-35/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master3 hash: 277780ac9fa6de28b5878a6281e9e60b
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-07-02-11-13-35/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master3 hash: 31d9ee8b7fb12e797dc981a8686f6b2b
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
sudo apt-get install kubeadm=1.15.0-00
sudo apt-mark hold kubeadm
```

2. Cordon the worker node, on the **Master node**, run:
```console
sudo kubectl drain $WORKERNODE --ignore-daemonsets
```
3. Upgrade the `kubelet` config on **worker nodes**
```console
sudo kubeadm upgrade node config --kubelet-version v1.15.0
```
4. Upgrade `kubelet` and `kubectl`
```console
sudo apt update && sudo apt upgrade
sudo apt-get install kubelet=1.15.0-00 kubectl=1.15.0-00
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
k8s-master1   Ready    master   21h   v1.15.0
k8s-master2   Ready    master   21h   v1.15.0
k8s-master3   Ready    master   21h   v1.15.0
k8s-worker1   Ready    <none>   20h   v1.15.0
k8s-worker2   Ready    <none>   20h   v1.15.0
k8s-worker3   Ready    <none>   20h   v1.15.0
```

