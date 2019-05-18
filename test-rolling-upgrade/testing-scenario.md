# Testing rolling upgrade [kubeadm HA Cluster](https://github.com/truongnh1992/upgrade-kubeadm-cluster/blob/master/upgrading-kubeadm-HA-cluster-from-v1.13.0-to-v1.13.5.md)

## Deloying [Node.js](https://github.com/truongnh1992/upgrade-kubeadm-cluster/blob/master/test-rolling-upgrade/app.js) app by creating a replication controller

On Master node 1:
```sh
master1@k8s-master1:~$ sudo kubectl run nht-rc --image=truongnh1992/test-ru --port=8080 --generator=run/v1

replicationcontroller/nht-rc created
```

Listing the pod:
```sh
master1@k8s-master1:~$ sudo kubectl get pods

NAME           READY   STATUS    RESTARTS   AGE
nht-rc-j9nt4   1/1     Running   0          25m
```

Scaling up the number of replicas of the above pod by changing the desired replica count on the ReplicationController:
```sh
master1@k8s-master1:~$ sudo kubectl scale rc nht-rc --replicas=3

replicationcontroller/nht-rc scaled
```

The result of the scale-out:
```sh
sudo kubectl get pods -o wide

NAME           READY   STATUS    RESTARTS   AGE    IP          NODE          NOMINATED NODE   READINESS GATES
nht-rc-j9nt4   1/1     Running   0          33m    10.42.0.1   k8s-worker1   <none>           <none>
nht-rc-mmxdp   1/1     Running   0          4m1s   10.39.0.1   k8s-worker2   <none>           <none>
nht-rc-s2bj7   1/1     Running   0          4m1s   10.40.0.1   k8s-worker3   <none>           <none>
```

Forwarding a local network port to a port in the pod
```sh
master1@k8s-master1:~$ sudo kubectl port-forward nht-rc-j9nt4 8888:8080
[sudo] password for master1:

Forwarding from 127.0.0.1:8888 -> 8080
Forwarding from [::1]:8888 -> 8080
Handling connection for 8888
Handling connection for 8888
Handling connection for 8888
Handling connection for 8888
...
```

Using the script ***check-downtime.sh*** to check the aliveness of port **nht-rc-j9nt4**
```sh
for (( ; ; ))
do
    sleep 1
    curl http://localhost:8888 &>> result.txt
done
```
![check-downtime](/test-rolling-upgrade/check_time.PNG)

## Upgrading kubeadm HA cluster

#### Upgrading the first control plane node (master 1)

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

kubeadm version: &version.Info{Major:"1", Minor:"13", GitVersion:"v1.13.5", GitCommit:"2166946f41b36dea2c4626f90a77706f426cdea2", GitTreeState:"clean", BuildDate:"2019-03-25T15:24:33Z", GoVersion:"go1.11.5", Compiler:"gc", Platform:"linux/amd64"}
```

4. Modify `configmap/kubeadm-config` for this control plane node, remove the `etcd` section completely
```sh
master1@k8s-master1:~$ kubectl edit configmap -n kube-system kubeadm-config

configmap/kubeadm-config edited
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

5. Start the upgrade
```sh
master1@k8s-master1:~$ sudo kubeadm upgrade apply v1.13.5
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
[upgrade/prepull] Prepulling image for component kube-controller-manager.
[upgrade/prepull] Prepulling image for component kube-apiserver.
[upgrade/prepull] Prepulling image for component kube-scheduler.
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 3 Pods for label selector k8s-app=upgrade-prepull-etcd
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Prepulled image for component kube-scheduler.
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Successfully prepulled the images for all the control plane components
[upgrade/apply] Upgrading your Static Pod-hosted control plane to version "v1.13.5"...
Static pod: kube-apiserver-k8s-master1 hash: 8e28bca62bcc383353621d65380af1e6
Static pod: kube-controller-manager-k8s-master1 hash: 2f207cd1681ef2ce2fdbd2377c677549
Static pod: kube-scheduler-k8s-master1 hash: 569c378f0859227e9c450c06e531daa2
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests770513425"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-28-40/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master1 hash: 8e28bca62bcc383353621d65380af1e6
Static pod: kube-apiserver-k8s-master1 hash: 04d287e345c55a49883273c8d8a08290
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-28-40/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master1 hash: 2f207cd1681ef2ce2fdbd2377c677549
Static pod: kube-controller-manager-k8s-master1 hash: 0a9f25af4e4ad5e5427feb8295fc055a
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-28-40/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master1 hash: 569c378f0859227e9c450c06e531daa2
Static pod: kube-scheduler-k8s-master1 hash: 569c378f0859227e9c450c06e531daa2
Static pod: kube-scheduler-k8s-master1 hash: 569c378f0859227e9c450c06e531daa2
Static pod: kube-scheduler-k8s-master1 hash: 569c378f0859227e9c450c06e531daa2
Static pod: kube-scheduler-k8s-master1 hash: 8cea5badbe1b177ab58353a73cdedd01
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.13" in namespace kube-system with the configuration for the kubelets in the cluster
[kubelet] Downloading configuration for the kubelet from the "kubelet-config-1.13" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "k8s-master1" as an annotation
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.13.5". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
  ```
</details>

#### Upgrading additional control plane nodes (Master 2 and Master 3)
Start the upgrade **Master 2**
```sh
master2@k8s-master2:~$ sudo kubeadm upgrade node experimental-control-plane
```
<details>
  <summary>The result:</summary>
  
```
[sudo] password for master2:
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.13.5"...
Static pod: kube-apiserver-k8s-master2 hash: f5c59ddc221ba4cc63858119e7c04612
Static pod: kube-controller-manager-k8s-master2 hash: 1fa1e5588240318e81fb48b5763529db
Static pod: kube-scheduler-k8s-master2 hash: 69aa2b9af9c518ac6265f1e8dce289a0
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests783137171"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-33-07/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master2 hash: f5c59ddc221ba4cc63858119e7c04612
Static pod: kube-apiserver-k8s-master2 hash: 1fbbeba86478edbba0719c8c5cc1a586
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-33-07/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master2 hash: 1fa1e5588240318e81fb48b5763529db
Static pod: kube-controller-manager-k8s-master2 hash: 0d778e323727eb1c5a1e6a163de25378
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-33-07/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master2 hash: 69aa2b9af9c518ac6265f1e8dce289a0
Static pod: kube-scheduler-k8s-master2 hash: 15c129447b0aa0f760fe2d7ba217ecd4
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upgrade] The control plane instance for this node was successfully updated!
```
</details>

Start the upgrade **Master 3**
```sh
master3@k8s-master3:~$ sudo kubeadm upgrade node experimental-control-plane
```
<details>
  <summary>The result:</summary>
  
```
[sudo] password for master3:
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.13.5"...
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-controller-manager-k8s-master3 hash: 1fa1e5588240318e81fb48b5763529db
Static pod: kube-scheduler-k8s-master3 hash: 69aa2b9af9c518ac6265f1e8dce289a0
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests984501917"
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-37-07/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: dddfb1cdaacdcffaac40af365b49f53a
Static pod: kube-apiserver-k8s-master3 hash: 45bc8f415732ad7a040e4331b7c57968
[apiclient] Found 3 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-37-07/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-k8s-master3 hash: 1fa1e5588240318e81fb48b5763529db
Static pod: kube-controller-manager-k8s-master3 hash: 0d778e323727eb1c5a1e6a163de25378
[apiclient] Found 3 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2019-05-18-02-37-07/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-k8s-master3 hash: 69aa2b9af9c518ac6265f1e8dce289a0
Static pod: kube-scheduler-k8s-master3 hash: 15c129447b0aa0f760fe2d7ba217ecd4
[apiclient] Found 3 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upgrade] The control plane instance for this node was successfully updated!
```
</details>

#### Upgrading worker nodes
Upgrade kubeadm on all worker nodes:

On worker 1:
```sh
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt upgrade
sudo apt-get install kubeadm=1.13.5-00
sudo apt-mark hold kubeadm
```
After that, the pod **nht-rc-j9nt4** restart, but the connection is still keeping.

![downtime](/test-rolling-upgrade/downtime.PNG)

The [result.txt](/test-rolling-upgrade/result.txt) to make sure that the connection to the pod **nht-rc-j9nt4** is still keeping.
