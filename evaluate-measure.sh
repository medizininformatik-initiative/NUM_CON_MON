#!/bin/bash -e

BASE="${1:-http://localhost:8080/fhir}"

if ! command -v blazectl &> /dev/null
then
    echo "blazectl could not be found. Please download it from https://github.com/samply/blazectl"
    exit 1
fi

VERSION=$(blazectl --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
REQUIRED_VERSION="1.0.0"

# Use sort -V to compare versions properly
if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$VERSION" | sort -V -C; then
    echo "Please use at leat version $REQUIRED_VERSION of blazectl for best experience."
    echo "Your current blazectl version is $VERSION."
    echo "Please download the newest version from https://github.com/samply/blazectl"
fi

if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please use your package manager to install it."
    exit 1
fi

if ! OUTPUT=$(blazectl --server "$BASE" evaluate-measure num-con-mon.yml); then
    echo
    echo "$OUTPUT"
    exit 1
fi

echo "$OUTPUT" > report.json
echo
echo "Finished generating the original MeasureReport saved under: report.json"

REPORT=$(./de-identify.sh < report.json | tee report-de-identified.json)

echo "Finished generating the de-identified MeasureReport saved under: report-de-identified.json"
echo
echo "Anzahl Patienten Kohorte 1: $(echo "$REPORT" | jq '.group[0].population[0].count')"
echo "Anzahl Patienten Kohorte 2: $(echo "$REPORT" | jq '.group[1].population[0].count')"
echo
echo "Aufschlüsselung für Kohorte 2:"
echo
echo "Liste absoluter Anzahlen der Kassenzugehörigkeit je Standort:"
echo "$REPORT" | jq -rf ik-number.jq | tee ik-number.csv
echo
echo "Liste absoluter Anzahlen der Fachabteilungen:"
echo "$REPORT" | jq -rf department-key.jq | tee department-key.csv
echo
echo "Liste absoluter Anzahlen der Geschlechter (männlich, weiblich):"
echo "$REPORT" | jq -rf gender.jq | tee gender.csv
echo
echo "Liste absoluter Anzahlen der Altersgruppen (<18J., 18-64J. und 65+J.):"
echo "$REPORT" | jq -rf age-class.jq | tee age-class.csv
