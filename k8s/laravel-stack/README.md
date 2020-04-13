# laraval-stack

This is a dev README who should be properly done only when solution is approved.

## 1. Create the cluster

No changes

## 2. Apply kind: Application CRD

No changes

## 3. Instal Kustomize and envsubst

```shell
curl -s "https://raw.githubusercontent.com/\
    kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

sudo mv kustomize /usr/local/bin/kustomize

apt -y install gettext-base
```

## 4. Install the App

### Navigate to folder
cd `click-to-deploy/k8s/laravel-stack`


### Set global vars
```shell
export APP_INSTANCE_NAME=hazelcast-1
export NAMESPACE=default
```

### Set image refs

```shell
TAG=7.3
export IMAGE_REGISTRY="gcr.io/orbitera-dev"
export IMAGE_LARAVEL="${IMAGE_REGISTRY}/laravel7"
export IMAGE_NGINX="${IMAGE_REGISTRY}/nginx1:1.16"
```

### Create certificate

```shell
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /tmp/tls.key \
    -out /tmp/tls.crt \
    -subj "/CN=nginx/O=nginx"

export TLS_CERTIFICATE_KEY="$(cat /tmp/tls.key | base64)"
export TLS_CERTIFICATE_CRT="$(cat /tmp/tls.crt | base64)"
```

### Import chart dependencies

```shell
../c2d_composer.sh --install
```

### Helm template

```shell

DIR=".deployable/base"
mkdir -p "${DIR}"

helm template chart/laravel-stack \
  --name "${APP_INSTANCE_NAME}" \
  --namespace "${NAMESPACE}" \
  --set nginx.tls.base64EncodedPrivateKey="$TLS_CERTIFICATE_KEY" \
  --set nginx.tls.base64EncodedCertificate="$TLS_CERTIFICATE_CRT" \
  --set nginx.metrics.exporter.enabled="false" \
  --set nginx.metrics.curatedExporter.enabled="false" \
  --output-dir "${DIR}"
```

### Setup kustomize files

```shell
../c2d_composer.sh --overlay
```

### Generate manifest file with kustomize

```shell
kustomize build .deployable/overlay --output "${APP_INSTANCE_NAME}_manifest.yaml"
```

### Apply manifest

```shell
kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"
```
