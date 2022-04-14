 Task 4

Check what I can do
```
$ kubectl auth can-i create deployments --namespace kube-system
yes
```
Configure user authentication using x509 certificates
Create private key
```
openssl genrsa -out k8s_user.key 2048
Generating RSA private key, 2048 bit long modulus
.............................................................................................................................................................+++
....+++
e is 65537 (0x10001)
```
Create a certificate signing request
```
$ openssl req -new -key k8s_user.key \
-out k8s_user.csr \
-subj "/CN=k8s_user"
```
Sign the CSR in the Kubernetes CA. We have to use the CA certificate and the key, which are usually in /etc/kubernetes/pki. But since we use minikube, the certificates will be on the host machine in ~/.minikube
```
$ openssl x509 -req -in k8s_user.csr \
-CA ~/.minikube/ca.crt \
-CAkey ~/.minikube/ca.key \
-CAcreateserial \
-out k8s_user.crt -days 500
Signature ok
subject=/CN=k8s_user
Getting CA Private Key
```
Create user in kubernetes
```
$ kubectl config set-credentials k8s_user \
--client-certificate=k8s_user.crt \
--client-key=k8s_user.key
User "k8s_user" set.
```
Set context for user
```
kubectl config set-context k8s_user \
--cluster=minikube --user=k8s_user
Context "k8s_user" created.
```
Edit ~/.kube/config
```
- name: k8s_user
  user:
    client-certificate: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/k8s_user.crt
    client-key: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/k8s_user.key
- context:
    cluster: minikube
    user: k8s_user
  name: k8s_user
```
Switch to use new context
```
kubectl config use-context k8s_user
Switched to context "k8s_user".
```
Check privileges
```
$ kubectl get node
Error from server (Forbidden): nodes is forbidden: User "k8s_user" cannot list resource "nodes" in API group "" at the cluster scope
$ kubectl get pod
Error from server (Forbidden): pods is forbidden: User "k8s_user" cannot list resource "pods" in API group "" in the namespace "default"
```
Switch to default(admin) context
```
kubectl config use-context minikube
Switched to context "minikube".
```
Bind role and clusterrole to the user
```
kubectl apply -f binding.yaml
rolebinding.rbac.authorization.k8s.io/k8s_user created
```
Check output
```
$ kubectl config use-context k8s_user                        
Switched to context "k8s_user".
$ kubectl get node                   
Error from server (Forbidden): nodes is forbidden: User "k8s_user" cannot list resource "nodes" in API group "" at the cluster scope
$ kubectl get pods 
NAME                    READY   STATUS    RESTARTS       AGE
minio-94fd47554-8fm8v   1/1     Running   2 (7h6m ago)   29h
minio-state-0           1/1     Running   2 (7h6m ago)   28h
nginx                   1/1     Running   1 (7h6m ago)   8h
web-6745ffd5c8-8hb9c    1/1     Running   1 (7h6m ago)   8h
web-6745ffd5c8-bl6nj    1/1     Running   1 (7h6m ago)   8h
web-6745ffd5c8-dstvh    1/1     Running   1 (7h6m ago)   8h
```
Now we can see pods

# Homework
* Create users deploy_view and deploy_edit. Give the user deploy_view rights only to view deployments, pods. Give the user deploy_edit full rights to the objects deployments, pods.

Create deploy_view_user
```
$ openssl genrsa -out deploy_view_user.key 2048
Generating RSA private key, 2048 bit long modulus
...................+++
...................................................................................+++
e is 65537 (0x10001)

$ openssl req -new -key deploy_view_user.key \
-out deploy_view_user.csr \
-subj "/CN=deploy_view_user"

$ openssl x509 -req -in deploy_view_user.csr \
-CA ~/.minikube/ca.crt \
-CAkey ~/.minikube/ca.key \
-CAcreateserial -out deploy_view_user.crt -days 500
Signature ok
subject=/CN=deploy_view_user
Getting CA Private Key

$ kubectl config set-credentials deploy_view_user \
--client-certificate=deploy_view_user.crt \
--client-key=deploy_view_user.key
User "deploy_view_user" set.

$ kubectl config set-context deploy_view_user \
--cluster=minikube \
--user=deploy_view_user
Context "deploy_view_user" created.

$ kubectl create clusterrole deploy_view_user \
--verb=get,list,watch \
--resource=pods,deployments
clusterrole.rbac.authorization.k8s.io/deploy_view_user created

$ nano ~/.kube/config 
```
```
- context:
    cluster: minikube
    user: deploy_view_user
  name: deploy_view_user

- name: deploy_view_user
  user:
    client-certificate: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/deploy_view_user.crt
    client-key: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/deploy_view_user.key
```

Bind role and clusterrole to the deploy_view_user
```
$ kubectl apply -f binding_deploy_view_user.yaml 
rolebinding.rbac.authorization.k8s.io/deploy_view_user created
```

Create deploy_edit_user
```
openssl genrsa -out deploy_edit_user.key 2048
Generating RSA private key, 2048 bit long modulus
..................................+++
....+++
e is 65537 (0x10001)
$ openssl req -new -key deploy_edit_user.key \
-out deploy_edit_user.csr \
-subj "/CN=deploy_edit_user"

$ openssl x509 -req -in deploy_edit_user.csr \
-CA ~/.minikube/ca.crt \
-CAkey ~/.minikube/ca.key \
-CAcreateserial -out deploy_edit_user.crt -days 500
Signature ok
subject=/CN=deploy_edit_user
Getting CA Private Key

$ kubectl config set-credentials deploy_edit_user \
--client-certificate=deploy_edit_user.crt \
--client-key=deploy_edit_user.key
User "deploy_edit_user" set.

$ kubectl config set-context deploy_edit_user \
--cluster=minikube \
--user=deploy_edit_user
Context "deploy_edit_user" created.

$ kubectl create clusterrole deploy_edit_user \
--verb=get,list,watch,create,update,patch,delete,deletecollection \
--resource=pods,deployments
clusterrole.rbac.authorization.k8s.io/deploy_edit_user created

$ nano ~/.kube/config
```
```
- context:
    cluster: minikube
    user: deploy_edit_user
  name: deploy_edit_user

- name: deploy_edit_user
  user:
    client-certificate: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/deploy_edit_user.crt
    client-key: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/deploy_edit_user.key
```

Bind role and clusterrole to the deploy_edit_user
```
kubectl apply -f binding_deploy_edit_user.yaml 
rolebinding.rbac.authorization.k8s.io/deploy_edit_user created
```

* Create namespace prod. Create users prod_admin, prod_view. Give the user prod_admin admin rights on ns prod, give the user prod_view only view rights on namespace prod.

Create prod namespace
```
$ kubectl create namespace prod
namespace/prod created
```

Create prod_admin
```
$ openssl genrsa -out prod_admin.key 2048 
Generating RSA private key, 2048 bit long modulus
.......+++
..................................................................+++
e is 65537 (0x10001)
$ openssl req -new -key prod_admin.key \
-out prod_admin.csr \
-subj "/CN=prod_admin"

$ openssl x509 -req -in prod_admin.csr \
-CA ~/.minikube/ca.crt \
-CAkey ~/.minikube/ca.key \
-CAcreateserial -out prod_admin.crt -days 500
Signature ok
subject=/CN=prod_admin
Getting CA Private Key

$ kubectl config set-credentials prod_admin \
--client-certificate=prod_admin.crt \
--client-key=prod_admin.key
User "prod_admin" set.

$ kubectl config set-context prod_admin \
--cluster=minikube \
--user=prod_admin
Context "prod_admin" created.

$ nano ~/.kube/config
```
```
- context:
    cluster: minikube
    user: prod_admin
  name: prod_admin

- name: prod_admin
  user:
    client-certificate: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/prod_admin.crt
    client-key: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/prod_admin.key
```

Bind role and clusterrole to the prod_admin
```
$ kubectl apply -f binding_prod_admin.yaml 
rolebinding.rbac.authorization.k8s.io/prod_admin created
```

Create prod_view
```
$ openssl genrsa -out prod_view.key 2048
Generating RSA private key, 2048 bit long modulus
.................+++
........+++
e is 65537 (0x10001)

$ openssl req -new -key prod_view.key \
-out prod_view.csr \
-subj "/CN=prod_view"

$ openssl x509 -req -in prod_view.csr \
-CA ~/.minikube/ca.crt \
-CAkey ~/.minikube/ca.key \
-CAcreateserial -out prod_view.crt -days 500
Signature ok
subject=/CN=prod_view
Getting CA Private Key

$ kubectl config set-credentials prod_view \
--client-certificate=prod_view.crt \
--client-key=prod_view.key
User "prod_view" set.

$ kubectl config set-context prod_view \
--cluster=minikube \
--user=prod_view
Context "prod_view" created.

$ nano ~/.kube/config
```
```
- context:
    cluster: minikube
    user: prod_view
  name: prod_view

- name: prod_view
  user:
    client-certificate: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/prod_view.crt
    client-key: /Users/demitov/DevOpsSchool/git-repo/Kubernetes/Task4/prod_view.key
```

Bind role and clusterrole to the prod_view
```
$ kubectl apply -f binding_prod_view.yaml 
rolebinding.rbac.authorization.k8s.io/prod_view created
```

Get contexts
```
$ kubectl config get-contexts 
CURRENT   NAME               CLUSTER    AUTHINFO           NAMESPACE
          deploy_edit_user   minikube   deploy_edit_user   
          deploy_view_user   minikube   deploy_view_user   
          k8s_user           minikube   k8s_user           
*         minikube           minikube   minikube           default
          prod_admin         minikube   prod_admin         
          prod_view          minikube   prod_view
```

Change context to prod_admin and try create deployment
```
$ kubectl create deployment nginx --image=nginx
error: failed to create deployment: deployments.apps is forbidden: User "prod_admin" cannot create resource "deployments" in API group "apps" in the namespace "default"

$ kubectl create deployment nginx --image=nginx --namespace prod
deployment.apps/nginx created

$ kubectl get deployments --namespace prod
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           37s
```

Change context to prod_view then try list and remove pod
```
$ kubectl config use-context prod_view 
Switched to context "prod_view".

$ kubectl get pods --namespace prod
NAME                     READY   STATUS    RESTARTS   AGE
nginx-85b98978db-ndrkd   1/1     Running   0          3m39s

$ kubectl delete pod ngnginx-85b98978db-ndrkd --namespace prod
Error from server (Forbidden): pods "ngnginx-85b98978db-ndrkd" is forbidden: User "prod_view" cannot delete resource "pods" in API group "" in the namespace "prod"
```

Change context to prod_admin and remove deployment
```
$ kubectl config use-context prod_view 
Switched to context "prod_view".

$ kubectl get pods --namespace prod
NAME                     READY   STATUS    RESTARTS   AGE
nginx-85b98978db-ndrkd   1/1     Running   0          3m39s

$ kubectl delete pod ngnginx-85b98978db-ndrkd --namespace prod
Error from server (Forbidden): pods "ngnginx-85b98978db-ndrkd" is forbidden: User "prod_view" cannot delete resource "pods" in API group "" in the namespace "prod"

$ kubectl config use-context prod_admin 
Switched to context "prod_admin".

$ kubectl get deployments --namespace prod
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           6m25s

$ kubectl delete deployments nginx --namespace prod
deployment.apps "nginx" deleted

$ kubectl get deployments --namespace prod         
No resources found in prod namespace.
```

* Create a serviceAccount sa-namespace-admin. Grant full rights to namespace default. Create context, authorize using the created sa, check accesses.

Create serviceAccount
```
$ kubectl create serviceaccount sa-namespace-admin
serviceaccount/sa-namespace-admin created
```

Create ClusterRoleBinding with role cluster-admin
```
$ kubectl create clusterrolebinding sa-namespace-admin --clusterrole=cluster-admin --serviceaccount=default:sa-namespace-admin
clusterrolebinding.rbac.authorization.k8s.io/sa-namespace-admin created
```

Get secret name created serviceAccount
```
$ export TOKENNAME=$(kubectl get serviceaccount/sa-namespace-admin -o jsonpath='{.secrets[0].name}')
$ echo $TOKENNAME
sa-namespace-admin-token-5kthn
```

Get the token from the base64 secret, decode it and add it to the TOKEN environment variable:
```
$ export TOKEN=$(kubectl get secret $TOKENNAME -o jsonpath='{.data.token}' | base64 --decode) 
$ echo $TOKEN
eyJhbGciOiJSUzI1NiIsImtpZCI6IjhidURCSmJ2bzhzc0kzTkhGV01oaU9sQVdvaE9Xd3FhMm56XzI1LUU2T2sifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6InNhLW5hbWVzcGFjZS1hZG1pbi10b2tlbi01a3RobiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJzYS1uYW1lc3BhY2UtYWRtaW4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI0MDM5NGZhMy03YTk1LTRhNzQtODRmMy04NTRmYTJhY2M5MmUiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDpzYS1uYW1lc3BhY2UtYWRtaW4ifQ.GPLAwxO_APo4Ef2DDZT99djsk7WKw4m7Ji0AWi76VFNsdsv9E9jrQl5BCV7S5Rv7-ufGGwDbYch3LRYLXmcS266jXUK1WIwN-1Qo0hZrsRcOZYgZASur-omQMxxLx9W7nNFEZcR929xHLsDUe6IXehq3l1nr7jImCfpyWO95Zln1QG-jVP_rQscXCll5xnjBgOivRcwMZiOGzF22MZ0tU8lOdJwKXO60g8dd1a_i3-xzy0NKvP2pJU5s-HId75GAM3WcUcftgkM1-2wzKop4o79x9LEW1eopvJX54ttd9_vpT0CgzADdf7R_VhMPKzTd0aHnqnIdy4-jGlelW4UTNA
```

Let's check the performance of the token, make a request to the Kubernetes API with the token in the "Authorization: Bearer" header:
```
$ curl -k -H "Authorization: Bearer $TOKEN" -X GET "https://$(minikube ip):8443/api/v1/nodes" | json_pp
```
<details>
  <summary>Output</summary>

```
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11343    0 11343    0     0  85931      0 --:--:-- --:--:-- --:--:-- 85931
{
   "apiVersion" : "v1",
   "items" : [
      {
         "metadata" : {
            "annotations" : {
               "kubeadm.alpha.kubernetes.io/cri-socket" : "/var/run/dockershim.sock",
               "node.alpha.kubernetes.io/ttl" : "0",
               "volumes.kubernetes.io/controller-managed-attach-detach" : "true"
            },
            "creationTimestamp" : "2022-04-12T15:39:43Z",
            "labels" : {
               "beta.kubernetes.io/arch" : "amd64",
               "beta.kubernetes.io/os" : "linux",
               "kubernetes.io/arch" : "amd64",
               "kubernetes.io/hostname" : "minikube",
               "kubernetes.io/os" : "linux",
               "minikube.k8s.io/commit" : "362d5fdc0a3dbee389b3d3f1034e8023e72bd3a7",
               "minikube.k8s.io/name" : "minikube",
               "minikube.k8s.io/primary" : "true",
               "minikube.k8s.io/updated_at" : "2022_04_12T19_39_47_0700",
               "minikube.k8s.io/version" : "v1.25.2",
               "node-role.kubernetes.io/control-plane" : "",
               "node-role.kubernetes.io/master" : "",
               "node.kubernetes.io/exclude-from-external-load-balancers" : ""
            },
            "managedFields" : [
               {
                  "apiVersion" : "v1",
                  "fieldsType" : "FieldsV1",
                  "fieldsV1" : {
                     "f:metadata" : {
                        "f:annotations" : {
                           "." : {},
                           "f:kubeadm.alpha.kubernetes.io/cri-socket" : {},
                           "f:volumes.kubernetes.io/controller-managed-attach-detach" : {}
                        },
                        "f:labels" : {
                           "." : {},
                           "f:beta.kubernetes.io/arch" : {},
                           "f:beta.kubernetes.io/os" : {},
                           "f:kubernetes.io/arch" : {},
                           "f:kubernetes.io/hostname" : {},
                           "f:kubernetes.io/os" : {},
                           "f:node-role.kubernetes.io/control-plane" : {},
                           "f:node-role.kubernetes.io/master" : {},
                           "f:node.kubernetes.io/exclude-from-external-load-balancers" : {}
                        }
                     }
                  },
                  "manager" : "Go-http-client",
                  "operation" : "Update",
                  "time" : "2022-04-12T15:39:46Z"
               },
               {
                  "apiVersion" : "v1",
                  "fieldsType" : "FieldsV1",
                  "fieldsV1" : {
                     "f:metadata" : {
                        "f:labels" : {
                           "f:minikube.k8s.io/commit" : {},
                           "f:minikube.k8s.io/name" : {},
                           "f:minikube.k8s.io/primary" : {},
                           "f:minikube.k8s.io/updated_at" : {},
                           "f:minikube.k8s.io/version" : {}
                        }
                     }
                  },
                  "manager" : "kubectl-label",
                  "operation" : "Update",
                  "time" : "2022-04-12T15:39:48Z"
               },
               {
                  "apiVersion" : "v1",
                  "fieldsType" : "FieldsV1",
                  "fieldsV1" : {
                     "f:metadata" : {
                        "f:annotations" : {
                           "f:node.alpha.kubernetes.io/ttl" : {}
                        }
                     },
                     "f:spec" : {
                        "f:podCIDR" : {},
                        "f:podCIDRs" : {
                           "." : {},
                           "v:\"10.244.0.0/24\"" : {}
                        }
                     }
                  },
                  "manager" : "kube-controller-manager",
                  "operation" : "Update",
                  "time" : "2022-04-12T15:39:59Z"
               },
               {
                  "apiVersion" : "v1",
                  "fieldsType" : "FieldsV1",
                  "fieldsV1" : {
                     "f:status" : {
                        "f:allocatable" : {
                           "f:memory" : {}
                        },
                        "f:capacity" : {
                           "f:memory" : {}
                        },
                        "f:conditions" : {
                           "k:{\"type\":\"DiskPressure\"}" : {
                              "f:lastHeartbeatTime" : {}
                           },
                           "k:{\"type\":\"MemoryPressure\"}" : {
                              "f:lastHeartbeatTime" : {}
                           },
                           "k:{\"type\":\"PIDPressure\"}" : {
                              "f:lastHeartbeatTime" : {}
                           },
                           "k:{\"type\":\"Ready\"}" : {
                              "f:lastHeartbeatTime" : {},
                              "f:lastTransitionTime" : {},
                              "f:message" : {},
                              "f:reason" : {},
                              "f:status" : {}
                           }
                        },
                        "f:images" : {},
                        "f:nodeInfo" : {
                           "f:bootID" : {},
                           "f:machineID" : {}
                        }
                     }
                  },
                  "manager" : "Go-http-client",
                  "operation" : "Update",
                  "subresource" : "status",
                  "time" : "2022-04-13T20:47:04Z"
               }
            ],
            "name" : "minikube",
            "resourceVersion" : "31347",
            "uid" : "9d08fb49-6452-4440-bd65-d6f89e53258f"
         },
         "spec" : {
            "podCIDR" : "10.244.0.0/24",
            "podCIDRs" : [
               "10.244.0.0/24"
            ]
         },
         "status" : {
            "addresses" : [
               {
                  "address" : "192.168.59.102",
                  "type" : "InternalIP"
               },
               {
                  "address" : "minikube",
                  "type" : "Hostname"
               }
            ],
            "allocatable" : {
               "cpu" : "2",
               "ephemeral-storage" : "17784752Ki",
               "hugepages-2Mi" : "0",
               "memory" : "2186464Ki",
               "pods" : "110"
            },
            "capacity" : {
               "cpu" : "2",
               "ephemeral-storage" : "17784752Ki",
               "hugepages-2Mi" : "0",
               "memory" : "2186464Ki",
               "pods" : "110"
            },
            "conditions" : [
               {
                  "lastHeartbeatTime" : "2022-04-14T13:39:13Z",
                  "lastTransitionTime" : "2022-04-12T15:39:40Z",
                  "message" : "kubelet has sufficient memory available",
                  "reason" : "KubeletHasSufficientMemory",
                  "status" : "False",
                  "type" : "MemoryPressure"
               },
               {
                  "lastHeartbeatTime" : "2022-04-14T13:39:13Z",
                  "lastTransitionTime" : "2022-04-12T15:39:40Z",
                  "message" : "kubelet has no disk pressure",
                  "reason" : "KubeletHasNoDiskPressure",
                  "status" : "False",
                  "type" : "DiskPressure"
               },
               {
                  "lastHeartbeatTime" : "2022-04-14T13:39:13Z",
                  "lastTransitionTime" : "2022-04-12T15:39:40Z",
                  "message" : "kubelet has sufficient PID available",
                  "reason" : "KubeletHasSufficientPID",
                  "status" : "False",
                  "type" : "PIDPressure"
               },
               {
                  "lastHeartbeatTime" : "2022-04-14T13:39:13Z",
                  "lastTransitionTime" : "2022-04-12T15:39:58Z",
                  "message" : "kubelet is posting ready status",
                  "reason" : "KubeletReady",
                  "status" : "True",
                  "type" : "Ready"
               }
            ],
            "daemonEndpoints" : {
               "kubeletEndpoint" : {
                  "Port" : 10250
               }
            },
            "images" : [
               {
                  "names" : [
                     "k8s.gcr.io/etcd@sha256:64b9ea357325d5db9f8a723dcf503b5a449177b17ac87d69481e126bb724c263",
                     "k8s.gcr.io/etcd:3.5.1-0"
                  ],
                  "sizeBytes" : 292558922
               },
               {
                  "names" : [
                     "k8s.gcr.io/ingress-nginx/controller@sha256:0bc88eb15f9e7f84e8e56c14fa5735aaa488b840983f87bd79b1054190e660de"
                  ],
                  "sizeBytes" : 285335078
               },
               {
                  "names" : [
                     "minio/minio@sha256:bc85be37d9e956383040b23c7f9522803443e26b323c04e099b1a6615e1627c4",
                     "minio/minio:latest"
                  ],
                  "sizeBytes" : 227202179
               },
               {
                  "names" : [
                     "kubernetesui/dashboard@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e",
                     "kubernetesui/dashboard:v2.3.1"
                  ],
                  "sizeBytes" : 220033604
               },
               {
                  "names" : [
                     "nginx@sha256:2275af0f20d71b293916f1958f8497f987b8d8fd8113df54635f2a5915002bf1",
                     "nginx:latest"
                  ],
                  "sizeBytes" : 141522028
               },
               {
                  "names" : [
                     "k8s.gcr.io/kube-apiserver@sha256:b8eba88862bab7d3d7cdddad669ff1ece006baa10d3a3df119683434497a0949",
                     "k8s.gcr.io/kube-apiserver:v1.23.3"
                  ],
                  "sizeBytes" : 135166371
               },
               {
                  "names" : [
                     "k8s.gcr.io/kube-controller-manager@sha256:b721871d9a9c55836cbcbb2bf375e02696260628f73620b267be9a9a50c97f5a",
                     "k8s.gcr.io/kube-controller-manager:v1.23.3"
                  ],
                  "sizeBytes" : 124979895
               },
               {
                  "names" : [
                     "k8s.gcr.io/kube-proxy@sha256:def87f007b49d50693aed83d4703d0e56c69ae286154b1c7a20cd1b3a320cf7c",
                     "k8s.gcr.io/kube-proxy:v1.23.3"
                  ],
                  "sizeBytes" : 112332215
               },
               {
                  "names" : [
                     "k8s.gcr.io/kube-scheduler@sha256:32308abe86f7415611ca86ee79dd0a73e74ebecb2f9e3eb85fc3a8e62f03d0e7",
                     "k8s.gcr.io/kube-scheduler:v1.23.3"
                  ],
                  "sizeBytes" : 53488311
               },
               {
                  "names" : [
                     "k8s.gcr.io/ingress-nginx/kube-webhook-certgen@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660"
                  ],
                  "sizeBytes" : 47736388
               },
               {
                  "names" : [
                     "k8s.gcr.io/coredns/coredns@sha256:5b6ec0d6de9baaf3e92d0f66cd96a25b9edbce8716f5f15dcd1a616b3abd590e",
                     "k8s.gcr.io/coredns/coredns:v1.8.6"
                  ],
                  "sizeBytes" : 46829283
               },
               {
                  "names" : [
                     "kubernetesui/metrics-scraper@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172",
                     "kubernetesui/metrics-scraper:v1.0.7"
                  ],
                  "sizeBytes" : 34446077
               },
               {
                  "names" : [
                     "gcr.io/k8s-minikube/storage-provisioner@sha256:18eb69d1418e854ad5a19e399310e52808a8321e4c441c1dddad8977a0d7a944",
                     "gcr.io/k8s-minikube/storage-provisioner:v5"
                  ],
                  "sizeBytes" : 31465472
               },
               {
                  "names" : [
                     "alpine@sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454",
                     "alpine:latest"
                  ],
                  "sizeBytes" : 5574964
               },
               {
                  "names" : [
                     "k8s.gcr.io/pause@sha256:3d380ca8864549e74af4b29c10f9cb0956236dfb01c40ca076fb6c37253234db",
                     "k8s.gcr.io/pause:3.6"
                  ],
                  "sizeBytes" : 682696
               }
            ],
            "nodeInfo" : {
               "architecture" : "amd64",
               "bootID" : "a62fbc54-9d12-4b6a-8a64-4995b3181d7b",
               "containerRuntimeVersion" : "docker://20.10.12",
               "kernelVersion" : "4.19.202",
               "kubeProxyVersion" : "v1.23.3",
               "kubeletVersion" : "v1.23.3",
               "machineID" : "d18cefb020504701b0756c438b35c8f3",
               "operatingSystem" : "linux",
               "osImage" : "Buildroot 2021.02.4",
               "systemUUID" : "884b447b-7e4c-4e46-89fd-f54f61af6c84"
            }
         }
      }
   ],
   "kind" : "NodeList",
   "metadata" : {
      "resourceVersion" : "31400"
   }
}
```

</details>

Add a service account to kubeconfig
```
$ kubectl config set-credentials sa-namespace-admin --token=$TOKEN
User "sa-namespace-admin" set.

$ kubectl config set-context sa-namespace-admin --cluster=minikube --user=sa-namespace-admin
Context "sa-namespace-admin" created.
```
Check
```
$ kubectl config get-contexts sa-namespace-admin 
CURRENT   NAME                 CLUSTER    AUTHINFO             NAMESPACE
          sa-namespace-admin   minikube   sa-namespace-admin
```