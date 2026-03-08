aws eks update-kubeconfig \
--name project-bedrock-cluster \
--region us-east-1

kubectl create namespace retail-app

kubectl apply -n retail-app -f \
https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml

kubectl get pods -n retail-app