sudo kubectl delete statefulset mysql
sudo kubectl delete svc mysql mysql-read
sudo kubectl delete pv mysql-pv-volume-0 mysql-pv-volume-1 mysql-pv-volume-2
sudo kubectl delete pvc data-mysql-0
sudo kubectl delete cm mysql
