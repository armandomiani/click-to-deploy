#!/bin/bash

destination_folder="chart/deps/charts"
if [[ ! -d "${destination_folder}" ]]; then
    mkdir -p "${destination_folder}"
fi

for solution in $(cat chart/deps/deps.json | jq -r '.[].solution'); do
    source_folder="../${solution}/chart/${solution}/templates"
    solution_destination_folder="${destination_folder}/${solution}"

    if [[ ! -d "${solution_destination_folder}" ]]; then
        mkdir -p "${solution_destination_folder}"
    fi

    echo "Importing ${solution}..."
    echo "Copying files from: ${source_folder}"

    find ${source_folder} -type f ! -name application.yaml -exec cp -f -v -t "${solution_destination_folder}" {} +

    current_dir="$(pwd)"
    current_solution="${current_dir##*/}"

    cp -Rf "${solution_destination_folder}/" "$(pwd)/chart/${current_solution}/templates"
done
