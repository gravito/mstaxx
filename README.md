# MStaxx Test Level#1
Using AWS provider and KOPS to create Kubernetes cluster. Can also do it manually by using --cloud-provider, but there are many small configurations needed  (such as making instance hostname to that of privateDNS, using tags etc.), troubleshooting which can waste valuable time.

## Please create following in AWS:
1. Create IAM role with Full Admin access on AWS.
1. Create a hosted Zone to work with KOPS. For this demo, we use Private Hosted Zone. Eg: test-aayush.com
1. Create a S3 bucket to store configuration files. Eg: s3aayush.com
   * You can enable versioning
   * Currently region is confined to us-east-1, as other regions require extra work.
1. Launch an EC2 instance, and attach Full Admin IAM role to it.

## Now we first install Kubectl and Kops. Run following commands:
   1. sudo apt-get update
   1. sudo apt-get install -y awscli
   1. aws configure
      * Enter your secret key and access key, default region and output format.
   1. curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
   1. chmod +x ./kubectl
   1. sudo mv ./kubectl /usr/local/bin/kubectl
   1. curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
   1. chmod +x kops-linux-amd64
   1. sudo mv kops-linux-amd64 /usr/local/bin/kops

## Now we work on creating AWS Cluster using KOPS. Run following commands:
1. export KOPS_STATE_STORE=s3://"your S3 bucket name"
   * your bucket name which you created earlier in AWS.
1. ssh-keygen
   * this is needed to create ssh keys to access master node
   * Select default option for this demo
1. kops create cluster --zones=ap-south-1a --cloud=aws --dns-zone="private DNS name" --dns=private --name=test.com
   * --zones: specifies the zone to provision cluster
   * --cloud: the cloud provider
   * --dns-zone: the dns zone you created earlier
1. kops update cluster test.com --yes
   * You can edit the master node or worker node properties like node counts, amis, node size etc. using "kops edit" command. It 
     would be displayed in the output.
1. kops validate cluster
1. kubectl get nodes --show-labels
1. ssh  -i ~/.ssh/id_rsa admin@api.test.com
   * Your EC2 instances would be visible in the dashboard. You can also fetch the master node IP address to ssh.
   * If used Ubuntu image for master, use ubuntu@ipaddress
  
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

