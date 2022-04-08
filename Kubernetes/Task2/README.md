# Task #2

## ConfigMap & Secrets
```
$ kubectl create secret generic connection-string --from-literal=DATABASE_URL=postgres://connect --dry-run=client -o yaml > secret.yaml

$ kubectl create configmap user --from-literal=firstname=firstname --from-literal=lastname=lastname --dry-run=client -o yaml > cm.yaml

$ kubectl apply -f secret.yaml
secret/connection-string created

$ kubectl apply -f cm.yaml
configmap/user created

$ kubectl apply -f pod.yaml
pod/nginx created
```

## Check env in pod
```
$ kubectl exec -it nginx -- bash

root@nginx:/# printenv
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_PORT=443
DATABASE_URL=postgres://connect
HOSTNAME=nginx
PWD=/
PKG_RELEASE=1~bullseye
HOME=/root
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
NJS_VERSION=0.7.2
TERM=xterm
SHLVL=1
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
lastname=lastname
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PORT=443
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
firstname=firstname
NGINX_VERSION=1.21.6
_=/usr/bin/printenv
root@nginx:/#
exit
```

## Create deployment with simple application
```
$ kubectl apply -f nginx-configmap.yaml
configmap/nginx-configmap created

$ kubectl apply -f deployment.yaml
deployment.apps/web created
```

## Get pod ip address
```
$ kubectl get pods -o wide
NAME                   READY   STATUS    RESTARTS     AGE   IP            NODE       NOMINATED NODE   READINESS GATES
nginx                  1/1     Running   1 (8d ago)   8d    172.17.0.4    minikube   <none>           <none>
web-6745ffd5c8-jwfhm   1/1     Running   1 (8d ago)   8d    172.17.0.7    minikube   <none>           <none>
web-6745ffd5c8-nzcf5   1/1     Running   1 (8d ago)   8d    172.17.0.2    minikube   <none>           <none>
web-6745ffd5c8-x455g   1/1     Running   1 (8d ago)   8d    172.17.0.10   minikube   <none>           <none>
```

#### Try connect to pod with curl (curl pod_ip_address). What happens?
- From you PC

```
$ curl 172.17.0.7
curl: (7) Failed to connect to 172.17.0.7 port 80: Operation timed out
```
- From minikube (minikube ssh)

```
$ minikube ssh
                         _             _            
            _         _ ( )           ( )           
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __  
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ curl 172.17.0.7
web-6745ffd5c8-jwfhm
```
- From another pod

```
$ kubectl exec -it web-6745ffd5c8-jwfhm -- bash
root@web-6745ffd5c8-jwfhm:/# curl 172.17.0.2
web-6745ffd5c8-nzcf5
```

## Create service (ClusterIP)

The command that can be used to create a manifest template
```
kubectl expose deployment/web --type=ClusterIP --dry-run=client -o yaml > service_template.yaml
```
Apply manifest
```
$ kubectl apply -f service_template.yaml
service/web created
```
Get service CLUSTER-IP
```
$ kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   9d
web          ClusterIP   10.109.109.159   <none>        80/TCP    63s
```

Try connect to service (curl service_ip_address). What happens?
- From you PC
```
curl 10.109.109.159
curl: (7) Failed to connect to 10.109.109.159 port 80: Operation timed out
```
- From minikube (minikube ssh) (run the command several times)
```
$ minikube ssh
                         _             _            
            _         _ ( )           ( )           
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __  
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ curl 10.109.109.159
web-6745ffd5c8-nzcf5
$ curl 10.109.109.159
web-6745ffd5c8-x455g
$ curl 10.109.109.159
web-6745ffd5c8-jwfhm
$ curl 10.109.109.159
web-6745ffd5c8-nzcf5
```

- From another pod (kubectl exec -it $(kubectl get pod |awk '{print $1}'|grep web-|head -n1) bash) (run the command several times)
```
kubectl exec -it $(kubectl get pod |awk '{print $1}'|grep web-|head -n1) bash

root@web-6745ffd5c8-jwfhm:/# curl 10.109.109.159
web-6745ffd5c8-nzcf5
root@web-6745ffd5c8-jwfhm:/# curl 10.109.109.159
web-6745ffd5c8-x455g
root@web-6745ffd5c8-jwfhm:/# curl 10.109.109.159
web-6745ffd5c8-x455g
root@web-6745ffd5c8-jwfhm:/# curl 10.109.109.159
web-6745ffd5c8-nzcf5
```

NodePort
```
$ kubectl apply -f service-nodeport.yaml
service/web-np created

$ kubectl get service
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        9d
web          ClusterIP   10.109.109.159   <none>        80/TCP         9m19s
web-np       NodePort    10.110.240.64    <none>        80:32086/TCP   50s
```

Checking the availability of the NodePort service type
```
$ minikube ip
192.168.59.101

$ curl 192.168.59.101:80
curl: (7) Failed to connect to 192.168.59.101 port 80: Connection refused

$ curl 192.168.59.101:32086
web-6745ffd5c8-x455g
```

DNS
Connect to any pod
```
$ kubectl exec -it $(kubectl get pod |awk '{print $1}'|grep web-|head -n1) bash

root@web-6745ffd5c8-jwfhm:/# cat /etc/resolv.conf
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local 
options ndots:5
root@web-6745ffd5c8-jwfhm:/# 
```

Use dnsutils
```
$ kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml
pod/dnsutils created

$ kubectl exec -ti dnsutils -- nslookup web.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web.default.svc.cluster.local
Address: 10.109.109.159

$ kubectl exec -ti dnsutils -- nslookup web-headless.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-headless.default.svc.cluster.local
Address: 172.17.0.2
Name:	web-headless.default.svc.cluster.local
Address: 172.17.0.7
Name:	web-headless.default.svc.cluster.local
Address: 172.17.0.10

```

Ingress

Enable Ingress controller
```
$ minikube addons enable ingress
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v1.1.1
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled

$ kubectl get pods -n ingress-nginx
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-v8jjn       0/1     Completed   0          18m
ingress-nginx-admission-patch-j6k55        0/1     Completed   1          18m
ingress-nginx-controller-cc8496874-nqhd4   1/1     Running     0          18m

$ kubectl get pod $(kubectl get pod -n ingress-nginx|grep ingress-nginx-controller|awk '{print $1}') -n ingress-nginx -o yaml
```

Create Ingress
```
$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/ingress-web created

$ curl $(minikube ip)
web-6745ffd5c8-jwfhm
```

# Homework

In Minikube in namespace kube-system, there are many different pods running. Your task is to figure out who creates them, and who makes sure they are running (restores them after deletion).

```
kubelet

An agent that runs on each node in the cluster. It makes sure that containers are running in a Pod.
The kubelet takes a set of PodSpecs that are provided through various mechanisms and ensures that
the containers described in those PodSpecs are running and healthy. The kubelet doesn't manage
containers which were not created by Kubernetes.
```

Implement Canary deployment of an application via Ingress. Traffic to canary deployment should be redirected if you add "canary:always" in the header, otherwise it should go to regular deployment. Set to redirect a percentage of traffic to canary deployment.

```
$ kubectl get ingress
NAME          CLASS    HOSTS   ADDRESS          PORTS   AGE
ingress-web   <none>   *       192.168.59.101   80      40h
$ curl $(minikube ip)
web-6745ffd5c8-nzcf5
$ kubectl get deploy -n ingress-nginx
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
ingress-nginx-controller   1/1     1            1           41h
```
Create:
- canary-deployment.yaml
- canary-ingress.yaml
- canary-service.yaml
and apply them
```
$ kubectl apply -f canary-deployment.yaml 
deployment.apps/web-canary created

$ kubectl apply -f canary-ingress.yaml 
ingress.networking.k8s.io/ingress-web configured

$ kubectl apply -f canary-service.yaml 
service/web-canary created
```

Testing Canary
```
$ curl $(minikube ip)
web-6745ffd5c8-x455g
 curl $(minikube ip)
web-6745ffd5c8-x455g
$ curl $(minikube ip)
web-6745ffd5c8-jwfhm
$ curl $(minikube ip)
web-6745ffd5c8-jwfhm
$ curl $(minikube ip)
web-6745ffd5c8-nzcf5
$ curl $(minikube ip)
web-6745ffd5c8-x455g

$ curl -H "canary:always" $(minikube ip)
web-canary-59dbddbb7f-r884q
$ curl -H "canary:always" $(minikube ip)
web-canary-59dbddbb7f-8h56r
$ curl -H "canary:always" $(minikube ip)
web-canary-59dbddbb7f-8h56r
$ curl -H "canary:always" $(minikube ip)
web-canary-59dbddbb7f-sfqdf
```
