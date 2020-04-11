
export APP_INSTANCE_NAME="laravel-1"
export NAMESPACE="default"

function apply_app() {
    kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
}

function template() {
    export TLS_CERTIFICATE_KEY="$(cat /tmp/tls.key | base64)"
    export TLS_CERTIFICATE_CRT="$(cat /tmp/tls.crt | base64)"

    helm template chart/laravel-stack \
        --name "${APP_INSTANCE_NAME}" \
        --namespace "${NAMESPACE}" \
        --set nginx.tls.base64EncodedPrivateKey="$TLS_CERTIFICATE_KEY" \
        --set nginx.nginx.tls.base64EncodedCertificate="$TLS_CERTIFICATE_CRT" \
        > ${APP_INSTANCE_NAME}_manifest.yaml
  echo "Template OK!"
}

function create_cert() {
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /tmp/tls.key \
        -out /tmp/tls.crt \
        -subj "/CN=nginx/O=nginx"
}

function apply() {
    kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"
}

function delete_all() {
    kubectl delete -f "${APP_INSTANCE_NAME}_manifest.yaml"
}

function attach() {
    kubectl exec -ti "${APP_INSTANCE_NAME}-$1" bash
}
