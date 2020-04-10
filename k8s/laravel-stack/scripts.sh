
export APP_INSTANCE_NAME="laravel-1"
export NAMESPACE="default"

function apply_app() {
    kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
}

function template() {
    helm template chart/laravel-stack \
        --name "${APP_INSTANCE_NAME}" \
        --namespace "${NAMESPACE}" \
        > ${APP_INSTANCE_NAME}_manifest.yaml
  echo "Template OK!"
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
