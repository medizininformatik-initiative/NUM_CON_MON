# NUM-CON-MON

CQL Measure for the NUM-CON-MON project, including test data.

# Deployment

Steps for Deployment are described [here](DEPLOYMENT.md).

# Test

## Prerequisites

### Babashka (only for generating the test data)

```sh
brew install borkdude/brew/babashka
```

### Docker

For running the test environment including Blaze.

### blazectl

For evaluating the measure. Can be downloaded [here](https://github.com/samply/blazectl). Measures can also be executed manually via FHIR API and $evaluate-measure FHIR Operation. blazectl just uses that FHIR API.

### jq

For creating the CSV files.

## Run Blaze

```sh
docker compose up -d
```

## Generate Data

```sh
./gen-test-data.clj
```

## Import Data

```sh
./import-data.sh
```

## Evaluate Measure

```sh
./evaluate-measure.sh
```

## Upload MeasureReport

```sh
./send-report.sh report-de-identified.json http://localhost:8080/fhir
```

## Shutdown and Clear Data

```sh
docker compose down -v
```
