# NUM-CON-MON

CQL Measure for the NUM-CON-MON project, including test data.

## Prerequisites

### Babashka

```sh
brew install borkdude/brew/babashka
```

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

## Shutdown and Clear Data

```sh
docker compose down -v
```
