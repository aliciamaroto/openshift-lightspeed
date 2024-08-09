#!/bin/sh
SUBSCRIPTION_ID=$(az account subscription list -o json | jq -r '.[0].subscriptionId')

# Create resource group
#az group create --name OAIResourceGroup --location francecentral

# Create resource OpenAI
#az cognitiveservices account create --name MyOpenAIResource --resource-group OAIResourceGroup --location francecentral --kind OpenAI --sku s0 \
#--subscription $SUBSCRIPTION_ID

# Get endpoint URL
ENDPOINT=$(az cognitiveservices account show --name MyOpenAIResource --resource-group OAIResourceGroup | jq -r .properties.endpoint)
echo $ENDPOINT

# Get the primary API Key
PRIMARY_API_KEY=$(az cognitiveservices account keys list --name MyOpenAIResource --resource-group  OAIResourceGroup | jq -r .key1)
echo $PRIMARY_API_KEY

az cognitiveservices account deployment create --name MyOpenAIResource --resource-group  OAIResourceGroup --deployment-name myModel --model-name gpt-35-turbo-16k --model-version "0613" --model-format OpenAI --sku-capacity "1" --sku-name "Standard"

#Create OpenShift secret
#oc create secret generic credentials --namespace=openshift-lightspeed --from-literal=apitoken=$PRIMARY_API_KEY

# Create OpenShift Lightspeed custom resource file

cat <<EOF > olsconfig.yaml
apiVersion: ols.openshift.io/v1alpha1
kind: OLSConfig
metadata:
  name: cluster
spec:
  llm:
    providers:
      - credentialsSecretRef:
          name: credentials
        deploymentName: myModel
        models:
          - name: gpt-35-turbo-16k
        name: myAzure
        type: azure_openai
        url: $ENDPOINT
  ols:
    defaultModel: gpt-35-turbo-16k
    defaultProvider: myAzure
    logLevel: DEBUG
EOF

oc apply -f olsconfig.yaml -n openshift-lightspeed