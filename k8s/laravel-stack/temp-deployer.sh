#!/bin/bash

while [[ "$#" != 0 ]]; do
  case "$1" in
    --command)
      command="$2"
      shift 2
      ;;
    *)
      echo "Unsupported flag: $1 - EXIT"
      exit 1
  esac
done;

function build() {
  destination_folder="chart/deps/charts"
  if [[ ! -d "${destination_folder}" ]]; then
      mkdir -p "${destination_folder}"
  fi

  for solution in $(cat chart/deps/deps.json | jq -r '.[].solution'); do
      source_folder="../${solution}/chart/${solution}"
      solution_destination_folder="${destination_folder}/${solution}"

      current_dir="$(pwd)"
      current_solution="${current_dir##*/}"

      if [[ ! -d "${solution_destination_folder}" ]]; then
          mkdir -p "${solution_destination_folder}"
      fi

      echo "Importing ${solution}..."
      echo "Copying files from: ${source_folder}"
      cp -Rfv "${source_folder}/" "$(pwd)/chart/deps/charts/"

      echo "Removing: $(pwd)/chart/deps/charts/${solution}/templates/application.yaml"
      rm -fv "$(pwd)/chart/deps/charts/${solution}/templates/application.yaml"
      # rm -fv "$(pwd)/chart/deps/charts/${solution}/Chart.yaml"
      # rm -fv "$(pwd)/chart/deps/charts/${solution}/values.yaml"
      # rm -fv "$(pwd)/chart/deps/charts/${solution}/logo.png"


      # cp -Rf "${solution_destination_folder}/" "$(pwd)/chart/${current_solution}/templates"
  done

  cp -Rf "${destination_folder}" "$(pwd)/chart/${current_solution}"
}

function destroy() {
 rm -rfv chart/deps/charts
}

if [[ "${command}" == "build" ]]; then
  build
  # destroy
elif [[ "${command}" == "destroy" ]]; then
  destroy
fi
