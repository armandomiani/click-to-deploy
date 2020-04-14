#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

while [[ "$#" != 0 ]]; do
  case "$1" in
    --release-name)
      release_name="$2"
      shift 2
      ;;
    --install)
      command="install"
      shift 1
      ;;
    --overlay)
      command="overlay"
      shift 1
      ;;
    --clean)
      command="clean"
      shift 1
      ;;
    --help)
      command="help"
      shift 1
      ;;
    *)
      echo "Unsupported flag: $1 - EXIT"
      exit 1
  esac
done;

function cli_header() {
  local cli_name=${0##*/}
    echo "$cli_name
click-to-deploy Composer CLI
----------------------------------"
}

function help() {
  local cli_name=${0##*/}
  echo "
$cli_name
click-to-deploy Composer CLI
Usage: $cli_name [--clean|--build]
Parameters:
  --clean     Clean all generated resources by a build
  --install   Install charts dependencies
  --help      Displays this output
  *           Help
"
  exit 1
}

function create_if_not_exists() {
  local directory="$1"
  if [[ ! -d "${directory}" ]]; then
    mkdir -p "${directory}"
  fi
}

function install_dependencies() {
  local current_dir="$(pwd)"
  local current_solution="${current_dir##*/}"

  echo "Current dir: ${current_dir}"
  echo "Current solution: ${current_solution}"

  destination_folder=".deps"
  create_if_not_exists "${destination_folder}"

  for importing_solution in $(cat chart/dependencies.json | jq -r '.[].solution'); do
    source_folder="../${importing_solution}/chart/${importing_solution}"
    deps_folder="${destination_folder}/${importing_solution}"

    create_if_not_exists "${deps_folder}"

    echo "Importing ${importing_solution}..."
    echo "Source: ${source_folder}"
    echo "To: ${deps_folder}"

    echo "Copying files from: ${source_folder}"
    cp -Rfv "${source_folder}/" "$(pwd)/.deps/"

    echo "Removing unwanted resources."
    rm -fv "${deps_folder}/templates/application.yaml"

    solution_charts_folder="$(pwd)/chart/${current_solution}/charts/"
    create_if_not_exists "${solution_charts_folder}"

    cp -Rf "${deps_folder}" "${solution_charts_folder}"
  done
}

function generate_base_kustomize() {
  local kustomization_file=".deployable/base/kustomization.yaml"

  local current_dir="$(pwd)"
  local current_solution="${current_dir##*/}"

  echo "Current dir: ${current_dir}"
  echo "Current solution: ${current_solution}"

  create_if_not_exists ".deployable/base"

  # Generate header file
  cat <<EOT > "${kustomization_file}"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
commonLabels:
  app.kubernetes.io/name: ${APP_INSTANCE_NAME}
resources:
EOT

  # # Generate resources
  for file in $(find chart/${current_solution}/ -name "*.yaml" | grep -v -E "(Chart.yaml|values.yaml)"); do
    echo "- ${file}" | sed "s/chart\///g" >> "${kustomization_file}"
  done

}

function generate_base_source() {
  echo "-> helm template here."
}

function generate_base() {
  generate_base_kustomize
  generate_base_source
}

function build_overlay() {
  local destination_folder=".deployable/overlay"
  echo "Release: ${APP_INSTANCE_NAME}"

  create_if_not_exists "${destination_folder}"

  for file in $(find chart/kustomize -type f); do
    filename="$(echo ${file} | awk -F '/' '{ print $NF }')"

    if [[ "${file}" == "chart/kustomize/kustomization.yaml" ]]; then
      cp -f "${file}" "${destination_folder}/${filename}"
    else
      echo "Source: ${file}"
      echo "Destination: ${destination_folder}"

      cat "${file}" | envsubst "\$APP_INSTANCE_NAME" > "${destination_folder}/${filename}"

      echo "----------"
    fi
  done
}

function generate_deployable() {
  generate_overlay
}

function apply_kustomize() {
 kustomize build .deployable/overlay
}

function clean() {
    for folder in .deps/ .deployable/; do
      rm -rfv "${folder}"
    done
    echo "All resource cleaned."
}

cli_header

if [[ "${command}" == "install" ]]; then
  install_dependencies
elif [[ "${command}" == "clean" ]]; then
  clean
elif [[ "${command}" == "overlay" ]]; then
  generate_base_kustomize
  build_overlay
elif [[ "${command}" == "help" ]]; then
  help
fi

