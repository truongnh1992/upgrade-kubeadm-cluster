# Upgrading kubeadm HA cluster from v1.13.0 to v1.13.5 (stacked etcd)

### Deploying multi-master nodes (High Availability) K8S
1. Follow the tutorial guide at: https://vietkubers.github.io/2019-01-31-ha-cluster-with-kubeadm.html
2. The result:

```sh
master1@k8s-master1:~$ sudo kubectl get node -o wide
NAME          STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8s-master1   Ready    master   25m   v1.13.0   10.164.178.161   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-master2   Ready    master   19m   v1.13.0   10.164.178.162   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-master3   Ready    master   18m   v1.13.0   10.164.178.163   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-worker1   Ready    <none>   12m   v1.13.0   10.164.178.233   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-worker2   Ready    <none>   12m   v1.13.0   10.164.178.234   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
k8s-worker3   Ready    <none>   11m   v1.13.0   10.164.178.235   <none>        Ubuntu 16.04.6 LTS   4.4.0-145-generic   docker://18.9.2
```

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
<details>
  <summary>yaml file</summary>
  
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
    kubernetesVersion: v1.13.0
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
  creationTimestamp: "2019-05-16T07:12:00Z"
  name: kubeadm-config
  namespace: kube-system
  resourceVersion: "1059"
  selfLink: /api/v1/namespaces/kube-system/configmaps/kubeadm-config
  uid: e613aec2-77a9-11e9-8d75-0800270fde1d

```
</details>

5. Remove the `etcd` section completely

6. Start the upgrade
```sh
sudo kubeadm upgrade apply v1.13.5
```

<details>
  <summary>The result:</summary>
  
```
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade/apply] Respecting the --cri-socket flag that is set with higher priority than the config file.
[upgrade/version] You have chosen to change the cluster version to "v1.13.5"
[upgrade/versions] Cluster version: v1.13.0
[upgrade/versions] kubeadm version: v1.13.5
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
[upgrade/prepull] Will prepull images for components [kube-apiserver kube-controller-manager kube-scheduler etcd]
[upgrade/prepull] Prepulling image for component etcd.
[upgrade/prepull] Prepulling image for component kube-apiserver.
[upgrade/prepull] Prepulling image for component kube-controller-manager.
[upgrade/prepull] Prepulling image for component kube-scheduler.
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-etcd
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Prepulled image for component kube-scheduler.
[upgrade/prepull] Successfully prepulled the images for all the control plane components
[upgrade/apply] Upgrading your Static Pod-hosted control plane to version "v1.13.5"...
Static pod: kube-apiserver-k8s-master1 hash: 8e28bca62bcc383353621d65380af1e6
Static pod: kube-controller-manager-k8s-master1 hash: 2f207cd1681ef2ce2fdbd2377c677549
Static pod: kube-scheduler-k8s-master1 hash: 569c378f0859227e9c450c06e531daa2
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests907838474"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/01-20-47/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master1 hash: 04d287e345c55a49883273c8d8a08290
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/ku19-05-16-01-20-47/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master1 hash: 2f207cd1681ef2ce2fdbd2377c677549
Static pod: kube-controller-manager-k8s-master1 hash: 0a9f25af4e4ad5e5427feb8295fc055a
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/01-20-47/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master1 hash: 569c378f0859227e9c450c06e531daa2
Static pod: kube-scheduler-k8s-master1 hash: 8cea5badbe1b177ab58353a73cdedd01
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.13" in namespace kube-system with the configuration for the kubelets in the cluster
[kubelet] Downloading configuration for the kubelet from the "kubelet-config-1.13" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "k8s-master1" as an annotation
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credent
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.13.5". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```
</details>

### Upgrading additional control plane nodes
Start the upgrade
```sh
sudo kubeadm upgrade node experimental-control-plane
```
<details>
  <summary>The result:</summary>
  
 ```
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.13.5"...
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-controller-manager-k8s-master3 hash: 1fa1e5588240318e81fb48b5763529db
Static pod: kube-scheduler-k8s-master3 hash: 69aa2b9af9c518ac6265f1e8dce289a0
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests349996627"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-                      backup-manifests-2019-05-16-01-28-19/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: 45bc8f415732ad7a040e4331b7c57968
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp                      /kubeadm-backup-manifests-2019-05-16-01-28-19/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master3 hash: 1fa1e5588240318e81fb48b5763529db
Static pod: kube-controller-manager-k8s-master3 hash: 0d778e323727eb1c5a1e6a163de25378
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-                      backup-manifests-2019-05-16-01-28-19/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master3 hash: 69aa2b9af9c518ac6265f1e8dce289a0
Static pod: kube-scheduler-k8s-master3 hash: 15c129447b0aa0f760fe2d7ba217ecd4
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upgrade] The control plane instance for this node was successfully updated!
```
</details>
