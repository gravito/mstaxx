# MStaxx Test Level#1
Using AWS provider and KOPS to create Kubernetes cluster. Can also do it manually by using --cloud-provider, but there are many small configurations needed  (such as making instance hostname to that of privateDNS, using tags etc.), troubleshooting which can waste valuable time.

## Please create following in AWS:
1. Create IAM role with Full Admin access on AWS.
1. Create a hosted Zone to work with KOPS. For this demo, we use Private Hosted Zone. Eg: test-aayush.com
1. Create a S3 bucket to store configuration files. Eg: s3aayush.com
   * You can enable versioning
1. Use aws configure command to configure access and secret keys.

## Now we first install Kubectl and Kops. Run following commands:
   1. sudo apt-get install awscli
   1. sudo apt-get update && sudo apt-get install -y apt-transport-https
   1. curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   1. echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   1. sudo apt-get update
   1. sudo apt-get install -y kubectl
   1. wget https://github.com/kubernetes/kops/releases/download/1.10.0/kops-linux-amd64
   1. chmod +x kops-linux-amd64
   1. mv kops-linux-amd64 /usr/local/bin/kops

## Now we work on creating AWS Cluster using KOPS. Run following commands:
1. export KOPS_STATE_STORE=s3://"your S3 bucket name"
   * your bucket name which you created earlier in AWS.
1. ssh-keygen
   * this is needed to create ssh keys to access master node
1. kops create cluster  --zones=ap-south-1a --cloud=aws --dns-zone="private DNS name" --dns=private --name=test.com
   * --zones: specifies the zone to provision cluster
   * --cloud: the cloud provider
   * --dns-zone: the dns zone you created earlier
1. kops update cluster test.com --yes
   * Note: If you get "UNABLE TO CREATE PERSISTENT VOLUME" error, try running following command before creating cluster:
   
     kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/storage-class/aws/default.yaml
   * You can also edit the master node or worker node properties like node counts, amis, node size etc. using "kops edit" command. It 
     would be displayed in the output.
1. ssh  -i ~/.ssh/id_rsa admin@public-ip-master-node
   * Your EC2 instances would be visible in the dashboard. Fetch the master node IP address.
   * If used Ubuntu image for master, use ubuntu@ipaddress
1. kubectl get nodes
  
## Now Kubernetes cluster has been created, create Ngninx Ingress controller for Load Balancing. We are using L4 ELB. Run following commands:
1. kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
1. kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/service-l4.yaml
1. kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/patch-configmap-l4.yaml

## Now we deploy Guest-Book application in the two namespaces.
1. kubectl create namespace staging
1. kubectl create namespace production
### For Staging:
1. kubectl config set-context --current --namespace=staging
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-deployment.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-service.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-slave-deployment.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-slave-service.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/frontend-deployment.yaml
1. kubectl apply -f frontend_modified.yaml
### For Production:
1. kubectl config set-context --current --namespace=production
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-deployment.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-service.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-slave-deployment.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/redis-slave-service.yaml
1. kubectl apply -f https://k8s.io/examples/application/guestbook/frontend-deployment.yaml
1. kubectl apply -f frontend_modified.yaml

## Now we create ingress controller for both namespaces.
1. kubectl config set-context --current --namespace=ingress-nginx
1. kubectl apply -f ingress_staging.yaml
1. kubectl apply -f ingress_production.yaml
1. Now, point the DNS hostname "staging-guestbook.mstakx.io" and "guestbook.mstakx.io" to ELB, and your ELB would automatically route the traffic to the required service.

## To replicate CPU Load stress test, run following commands in each individual namespace
1. kubectl config set-context --current --namespace=staging
1. chmod 777 test.sh
1. ./test.sh
   * You can observe spike in CPU Load, and replication of 5 controllers.
1. kubectl config set-context --current --namespace=staging
1. chmod 777 test.sh
1. ./test.sh
   * You can observe spike in CPU Load, and replication of 5 controllers.

## You can run entire kubernetes deployment using wrapper script. Prerequisite is that AWS Cluster should be deployed using KOPS.
1. ./wrapper.sh

