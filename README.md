# PlatformCon 2024 Demonstration

Though it's widely acknowledged that developers should prioritize business logic over the complexities of deploying and maintaining applications, executing this seamlessly while incorporating considerations for governance, flexibility, and simplicity proves challenging. The OAM addresses this challenge by standardizing cloud-native application definitions, thereby closing the gap between developers and operators. Explore the implementation of OAM with KubeVela and Crossplane to streamline development, bolster security, and facilitate scalable infrastructure management.

**PlatformCon 2024 Session:** [Empowering platform engineering: Unleashing the potential of KubeVela and Crossplane](https://platformcon.com/talks/empowering-platform-engineering-unleashing-the-potential-of-kubevela-and-crossplane)

## Getting Started

To get started with this repository and test KubeVela and Crossplane using the provided resources, you'll need to have the necessary tools installed and your environment configured:
- [Amazon EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [jq](https://jqlang.github.io/jq/download/)
- [Install KubeVela](https://kubevela.io/docs/installation/kubernetes/)
- [Install Crossplane](https://docs.crossplane.io/latest/software/install/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

After you finished the requirements, clone the repository

```bash
git clone https://github.com/tiagoReichert/platformcon-kubevela-crossplane.git
cd platformcon-kubevela-crossplane/
```

Create KubeVela `three-tier-app` [custom component](https://kubevela.io/docs/platform-engineers/components/custom-component/) and `ddb-table` [custom trait](https://kubevela.io/docs/platform-engineers/traits/customize-trait/)
```bash
# Export your EKS Cluster Name and AWS Account ID (change here)
export EKS_CLUSTER_NAME=XXXXXXXXXXXX
export AWS_ACCOUNT_ID=XXXXXXXXXXXX

# Replace OIDC_ID and AWS_ACCOUNT_ID on three-tier-app-db-trait.cue
OIDC_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
sed -i "s|{OIDC_ID}|${OIDC_ID}|g" "demonstration/three-tier-app-db-trait.cue"
sed -i "s|{AWS_ACCOUNT_ID}|${AWS_ACCOUNT_ID}|g" "demonstration/three-tier-app-db-trait.cue"

# Create custom component and custom trait
vela def apply demonstration/three-tier-app.cue
vela def apply demonstration/three-tier-app-db-trait.cue
```

Create Crossplane Providers. During the **PlatformCon 2024** demonstration we created an [Amazon DynamoDB](https://aws.amazon.com/pt/dynamodb/) table and an [AWS IAM](https://aws.amazon.com/pt/iam/) role with permission for the application to read and write to the table using [IAM roles for service accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

```bash
kubectl apply -f demonstration/aws-providers.yml 
```

You will also need to create a `ProviderConfig` to give permission for Crossplane to create resources in your AWS account. You can use [this documentation as a reference](https://docs.upbound.io/providers/provider-aws/authentication/#iam-roles-for-service-accounts) and remember to use the [principle of least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege).

### Deploy the three-tier-app Application

Now that you have Crossplane and KubeVela configured, build the `frontend` and `backend` container images with a simple application to demonstrate the usage of  the `three-tier-app` custom component.
During the demonstration at **PlatformCon 2024** we used [Amazon ECR](https://aws.amazon.com/ecr/) to store the container images.

```bash
# Create Amazon ECR Repositories
export BACKEND_ECR_URI=$(aws ecr create-repository --repository-name backend | jq -r '.repository.repositoryUri')
export FRONTEND_ECR_URI=$(aws ecr create-repository --repository-name frontend | jq -r '.repository.repositoryUri')

# Build and Push the Frontend Container
docker build -t $FRONTEND_ECR_URI:0.0.1 frontend/
aws ecr get-login-password | docker login --username AWS --password-stdin $FRONTEND_ECR_URI
docker push $FRONTEND_ECR_URI:0.0.1

# Build and Push the Frontend Container
docker build -t $BACKEND_ECR_URI:0.0.1 backend/
aws ecr get-login-password | docker login --username AWS --password-stdin $BACKEND_ECR_URI
docker push $BACKEND_ECR_URI:0.0.1
```

To deploy the `three-tier-app` application using the `custom component` from KubeVela all you need to do is create an `Application`:
```bash
# Add ECR repository URI to the application.yml file
sed -i "s|{FRONTEND_CONTAINER_IMAGE}|${FRONTEND_ECR_URI}:0.0.1|g" "demonstration/application.yml"
sed -i "s|{BACKEND_CONTAINER_IMAGE}|${BACKEND_ECR_URI}:0.0.1|g" "demonstration/application.yml"

# Create the Application
kubectl create ns my-app-ns
kubectl apply -f demonstration/application.yml
```

Check if the application was successfully deployed:
```bash
# Check the KubeVela Application
vela status my-app -n my-app-ns

# Check the Crossplane resources
kubectl get managed -n my-app-ns

# Check the Kubernetes resources
kubectl get all -n my-app-ns

# Get Load Balancer URL to access the application
echo http://$(kubectl get ingress -n my-app-ns -o json | jq -r '.items[0].status.loadBalancer.ingress[0].hostname')
```

## License
This project is licensed under the terms of the [MIT license](LICENSE).