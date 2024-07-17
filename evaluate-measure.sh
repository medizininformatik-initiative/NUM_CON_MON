#!/bin/bash -e

BASE="${1:-http://localhost:8080/fhir}"

if ! command -v blazectl &> /dev/null
then
    echo "blazectl could not be found. please download it from https://github.com/samply/blazectl"
    exit 1
fi

REPORT=$(blazectl --server "$BASE" evaluate-measure num-con-mon.yml | tee report.json)

echo
echo "Finished generating the MeasureReport saved under: report.json"
echo
echo "Anzahl Patienten Kohorte 1: $(echo "$REPORT" | jq '.group[0].population[0].count')"
echo "Anzahl Patienten Kohorte 2: $(echo "$REPORT" | jq '.group[1].population[0].count')"
echo
echo "Aufschlüsselung für Kohorte 2:"
echo
echo "Liste prozentualer Anteile der Kassenzugehörigkeit je Standort:"
echo "$REPORT" | jq -rf ik-number.jq | tee ik-number.csv
echo
echo "Liste prozentualen Anteil der Fachabteilungen:"
echo "$REPORT" | jq -rf department-key.jq | tee department-key.csv
echo
echo "Liste prozentualer Anteile der Geschlechter (männlich, weiblich):"
echo "$REPORT" | jq -rf gender.jq | tee gender.csv
echo
echo "Liste prozentualer Anteile der Altersgruppen (<18J., 18-64J. und 65+J.):"
echo "$REPORT" | jq -rf age-class.jq | tee age-class.csv
