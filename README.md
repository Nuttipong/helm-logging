## Logging Architecture
Application logs can help you understand what is happening inside your application. The logs are particularly useful for debugging problems and monitoring cluster activity. Most modern applications have some kind of logging mechanism; as such, most container engines are likewise designed to support some kind of logging. The easiest and most embraced logging method for containerized applications is to write to the standard output and standard error streams.

However, the native functionality provided by a container engine or runtime is usually not enough for a complete logging solution. For example, if a container crashes, a pod is evicted, or a node dies, you'll usually still want to access your application's logs. As such, logs should have a separate storage and lifecycle independent of nodes, pods, or containers. This concept is called cluster-level-logging. Cluster-level logging requires a separate backend to store, analyze, and query logs. Kubernetes provides no native storage solution for log data, but you can integrate many existing logging solutions into your Kubernetes cluster.

### Cluster-level logging
Cluster-level logging architectures are described in assumption that a logging backend is present inside or outside of your cluster. If you're not interested in having cluster-level logging, you might still find the description of how logs are stored and handled on the node to be useful.

### S3 repository to store chart or package
bucket name: s3-cloudops-ec1-nonprod-logging-chart-bucket

### Helm S3 plugin required
helm plugin install https://github.com/hypnoglow/helm-s3.git
helm plugin will generates index.yaml by command below
> helm s3 init s3://s3-cloudops-ec1-logging-chart-bucket/charts

### Helm basic command
helm install <release-name> <chart-name>
> helm install dev logging-agent
helm list --short
helm get manifest <release-name> | less
> helm get manifest dev | less

### As Chart.yaml we'll update appVersion when we have a changes. So for this called release revision
- to deploy release revision
helm upgrade <release-name> <chart-name> 
- to check the revision
helm status <release-name>

### As Chart.yaml we'll update chart version when the structure changes. So we called release new version
- to release new version
helm install <release-name> <chart-name> 

### Rollback 
helm history <release-name> 
helm rollback <release-name> 1

### Delete
helm uninstall <release-name>

### Template
- To checking Helm template execution
helm template <release-name> | less
helm install <release-name> <chart-name> --dry-run --debug
> helm install dev logging-agent --dry-run --debug

### Adding template logic
More read http://masterminds.github.io/sprig

### Do overwritten in the values.yaml
>> do overwritten in the values.yaml
helm install dev <chart-name> --set config.env=DEV \
--set fluentEnvs.useRole=true \
--set fluentEnvs.roleARN=arn:aws:iam::012345678901:role/KinesisFirehose \
--set fluentEnvs.roleSession=kops-nodes

### Helm managing repo
helm repo add <myrep_alias> <url>
helm repo remove <myrep_alias>
> helm repo list
> helm repo add logging-agent ..

### Helm packaging
- tar -zcvf chart_name-chart_version.tgz chart_name
- helm package chart_name-chart_version (Recommended) or helm package .

### Helm push with s3 plugin
> helm s3 push ./logging-agent-1.1.0.tgz logging

### Helm search repo
helm search repo <repo_name>
> helm search repo logging

#### CloudTrail logs for analyze users and services activity for audit logs

### Daemonset
#0 - create service account, cluster-role, and cluster-role-binding
k get serviceaccounts
> k get serviceaccounts/fluentd -o yaml

#1 - create DaemonSet on all nodes
k get nodes
k get daemonset --namespace kube-system kube-proxy
k describe daemonsets <name>

#2 - create the Daemoset with Pods on each node in the cluster without the master
k create -f templates/fluentd-ds.yaml
k get daemonset
k get daemonset -o wide
k get pods --namespace=kube-system
k get pods -o wide
> k get pods --namespace kube-system -l app=logging-agent

#3 - change the lable to one of our Pods
k lable pods <my-pod> app=not --overwrite

### Terraform CLI using for example
```
terraform init
terraform workspace list
terraform workspace new nonprod
terraform workspace select nonprod
terraform validate
terraform plan -out state.tfplan -var-file="terraform.tfvars"
terraform apply "state.tfplan"
terraform destroy -auto-approve
```

### Step Helm Repository and Deploy
- Required first time only
1. helm plugin install https://github.com/hypnoglow/helm-s3.git
2. ~~helm s3 init s3://s3-cloudops-ec1-logging-charts-bucket~~
3. helm lint
4. helm package . or helm package logging-agent
5. helm repo index . -- or helm s3 init s3://s3-cloudops-ec1-logging-chart-bucket/charts
6. aws sts get-caller-identity --profile gbm-nonprod-autocicd
7. aws s3 ls s3-cloudops-ec1-logging-charts-bucket/charts --profile gbm-nonprod-terraform
8. terraform apply "state.tfplan"
9. helm repo add logging-agent s3://s3-cloudops-ec1-logging-charts-bucket
10. helm repo list
11. export AWS_PROFILE=gbm-nonprod-terraform
- Deploy package
12. helm s3 push logging-agent-1.1.0.tgz logging-agent
13. helm s3 push --force logging-agent-1.1.0.tgz logging-agent

### Development command uses
```
helm
> helm list --short
> helm install dev logging-agent --dry-run --debug
> helm install dev logging-agent
> helm uninstall dev
> helm upgrade dev logging-agent

helm packing & push
> helm package logging-agent
> helm s3 push logging-agent-1.1.2.tgz logging-agent
or
> helm s3 push --force logging-agent-1.1.2.tgz logging-agent

* Note that, we need to set ENV 
> export AWS_PROFILE=gbm-nonprod-terraform

k8s
> k get events -n=kube-system --sort-by='.metadata.creationTimestamp'
> k get pods -n=kube-system -l app=dev-logging-agent
> k get psp -n=kube-system -l app=dev-logging-agent
> k get serviceaccount -n=kube-system -l app=dev-logging-agent
> k get cm -n=kube-system dev-logging-agent-cm
> k get clusterroles fluentd-role -o yaml
> k get clusterrolebinding fluentd-role-binding -o yaml
> PODNAME=$(kubectl get pods -n=kube-system -l app=dev-logging-agent -o jsonpath='{ .items[0].metadata.name }')
> echo $PODNAME
> k logs $PODNAME
> k logs $PODNAME -n=kube-system -c container1
> k logs $PODNAME -n=kube-system --all-containers
> k logs $PODNAME -n=kube-system --all-containers --follow
> k logs $PODNAME -n=kube-system --tail 10
> k logs $PODNAME -n=kube-system --tail 10 logs.txt
> k get events -n=kube-system --sort-by='.metadata.creationTimestamp'
> k get events -n=kube-system --watch

get logs
> k logs dev-apcp-bpico-5674579949-t5wvz -n dev > logs.txt

exec pod with it
> k exec dev-logging-agent-9cpqc -n=kube-system -- cat /fluentd/etc/fluent.conf
> k exec -it dev-logging-agent-9cpqc -n=kube-system -- /bin/bash

exec node
> aws ssm start-session --target ip-44-130-8-52.eu-central-1.compute.internal --profile apcp-nonprod-dev-eksadmin

aws eks
> aws eks update-kubeconfig --name adpk8s-apcpuat --profile apcp-nonprod-uat-eksadmin
```

### Secret for Daemonset based on cluster
```
k apply -n kube-system -k .
```

### Test
```
aws firehose list-delivery-streams --profile gbm-nonprod-autocicd

aws firehose put-record-batch \
    --delivery-stream-name firehose_cloudops_ec1_nonprod_es \
    --records file://records.json \
    --profile gbm-nonprod-autocicd
```

### References
- fluentd: 
https://github.com/fluent/fluentd-kubernetes-daemonset

- aws fluent plugin:
https://github.com/awslabs/aws-fluent-plugin-kinesis

- kubernetes:
https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
https://kubernetes.io/docs/reference/access-authn-authz/rbac/
https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
https://kubernetes.io/docs/concepts/policy/pod-security-policy/
https://kubernetes.io/docs/concepts/cluster-administration/logging/

- docker:
https://docs.docker.com/config/containers/logging/configure/

- pod security:
https://docs.aws.amazon.com/eks/latest/userguide/pod-security-policy.html
https://kubernetes.io/docs/concepts/policy/pod-security-policy/
https://unofficial-kubernetes.readthedocs.io/en/latest/concepts/policy/pod-security-policy/

- aws vpc peering
https://medium.com/@devopslearning/introduction-to-vpc-peering-part-1-c385d2ff8138

- aws sts assume role
https://blog.container-solutions.com/how-to-create-cross-account-user-roles-for-aws-with-terraform

- aws firehose
https://docs.aws.amazon.com/cli/latest/reference/firehose/index.html