#!/bin/bash -e

BASE="${1:-http://localhost:8080/fhir}"

if ! command -v blazectl &> /dev/null
then
    echo "blazectl could not be found. please download it from https://github.com/samply/blazectl"
    exit 1
fi

blazectl --server "$BASE" count-resources
