## Run a Replicated Stateful Application

### Create a PersistentVolume referencing a disk in your environment 
Create `/data` directories on all of worker nodes
```console
worker@k8s-worker:~$ sudo mkdir /data
```
```console
master@k8s-master:~$ sudo kubectl apply -f ../yaml-files/mysql-pv.yaml --validate=false
```
### Deloy application

```console
master@k8s-master:~$ sudo kubectl apply -f ../yaml-files/mysql-configmap.yaml
master@k8s-master:~$ sudo kubectl apply -f ../yaml-files/mysql-services.yaml
master@k8s-master:~$ sudo kubectl apply -f ../yaml-files/mysql-statefulset.yaml
```

### The result
**master1@k8s-master1:~$** `sudo kubectl get all`
```console
NAME          READY   STATUS    RESTARTS   AGE
pod/mysql-0   2/2     Running   0          38m
pod/mysql-1   2/2     Running   0          37m
pod/mysql-2   2/2     Running   0          37m

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP    3d
service/mysql        ClusterIP   None           <none>        3306/TCP   38m
service/mysql-read   ClusterIP   10.108.95.75   <none>        3306/TCP   38m

NAME                     READY   AGE
statefulset.apps/mysql   3/3     38m
```
**master1@k8s-master1:~$** `sudo kubectl get pods -o wide`
```console
NAME      READY   STATUS    RESTARTS   AGE   IP          NODE          NOMINATED NODE   READINESS GATES
mysql-0   2/2     Running   0          38m   10.40.0.1   k8s-worker3   <none>           <none>
mysql-1   2/2     Running   0          38m   10.39.0.1   k8s-worker2   <none>           <none>
mysql-2   2/2     Running   0          38m   10.42.0.1   k8s-worker1   <none>           <none>
```
