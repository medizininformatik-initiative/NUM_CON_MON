# NUM-CON-MON

CQL Measure for the NUM-CON-MON project, including test data.

## Inhaltsverzeichnis

1. [Beschreibung](#beschreibung)
1. [Dateien](#dateien)
1. [Deployment](#deployment-)
    - [1. Evaluate Measure](#1-evaluate-measure)
    - [2. Upload MeasureReport](#2-upload-measurereport)
    - [3. Transfer MeasureReport vom DIZ zur HRP](#3-transfer-measurereport-vom-diz-zur-hrp)
1. [Voraussetzungen](#voraussetzungen)

---

## Beschreibung

1. Führt die Auswertung einer Measure Ressource auf einem FHIR-Server durch.
1. Extrahiert folgende Daten:
    - Gesamtanzahl der Patienten in zwei Kohorten.
    - Aufschlüsselung für Kohorte 2:
        - Verteilung der Kassenzugehörigkeit je Standort.
        - Verteilung nach Fachabteilungen.
        - Verteilung nach Geschlecht.
        - Verteilung nach Altersgruppen (<18 Jahre, 18–64 Jahre, 65+ Jahre).
1. Speichert die extrahierten Daten in CSV-Dateien für eine einfache Analyse und einer JSON Datei als FHIR MeasureReport. 

---

## Dateien

- `num-con-mon.yml`: Die Measure-Definition im YAML-Format.
- `num-con-mon-cql`: `cql`-Skript mit den Definitionen für die Ressourcen Zähĺungen
- `ik-number.jq`: `jq`-Script zur Bestimmung der Verteilung der Kassenzugehörigkeit.
- `department-key.jq`: `jq`-Script zur Bestimmung der Verteilung nach Fachabteilungen.
- `gender.jq`: `jq`-Script zur Bestimmung der Verteilung nach Geschlecht.
- `age-class.jq`: `jq`-Script zur Bestimmung der Verteilung nach Altersgruppen.
- `de-identify.jq`: `jq`-Script zur Anonymisierung von Daten durch Zusammenfassen von kleinen Populationen
- `util.jq`: `jq`-Script, das Hilfsfunktionen für die Verarbeitung von "data-absent-reason" & für die Zählungen von Daten definiert

---

## Deployment  

### 1. Evaluate Measure

Ausführung des Skripts `evaluat-measure.sh` mit Übergabe der URL des FHIR-Servers als Parameter. Wird keine URL angegeben, wird standardmäßig `http://localhost:8080/fhir` verwendet:

```bash
./evaluate-measure.sh [FHIR_SERVER_URL]
```

`evaluat-measure.sh` automatisiert die Auswertung einer Measure-YAML-Datei auf einem FHIR Server. 
Es wird ein detaillierter Bericht erstellt und spezifische Metriken in CSV-Dateien zur weiteren Analyse extrahiert.

Das Skript erzeugt folgende Dateien:
- **`report-de-identified.json`**: Der MeasureReport im JSON-Format.
- **`ik-number.csv`**: Verteilung der Kassenzugehörigkeit je Standort.
- **`department-key.csv`**: Verteilung nach Fachabteilungen.
- **`gender.csv`**: Verteilung nach Geschlecht.
- **`age-class.csv`**: Verteilung nach Altersgruppen.

---

### 2. Upload des MeasureReports

Für den Datentransfer per DSF muss der MeasureReport `report-de-identified.json` 
mit einer zugehörigen DocumentReference `your-dsf-fhir-server`, die der DSF BPE zugänglich ist 
an den FHIR Server geschickt werden. 
Wenn es bereits eine DocumentReference mit dem gleichen Projektidentifikationssystem und Wert 
auf dem FHIR Server gibt, wird die DocumentReference aktualisiert, 
um auf den neuen MeasureReport zu verweisen. Ein früherer MeasureReport wird nicht aktualisiert 
oder gelöscht und bleibt auf dem FHIR Server erhalten.

```bash
./send-report.sh report-de-identified.json http://localhost:8080/fhir
```

```
Usage: send-report.sh <report-file> <report-server>
       send-report.sh <report-file> <report-server> [-u <user> -p <password>]
       send-report.sh <report-file> <report-server> [-i <issuer-url> -c <client-id> -s <client-secret>]
```

---

### 3. Transfer des MeasureReports vom DIZ zur HRP

Mit dem [MII Data Transfer Process](https://github.com/medizininformatik-initiative/mii-process-data-transfer)
kann der MeasureReport vom ans DSF angeschlossenen DIZ FHIR Server an den HRP FHIR Server gesendet werden. 
Eine detaillierte Beschreibung des DataTransfer Prozesses kann [hier](https://github.com/medizininformatik-initiative/mii-process-data-transfer/wiki)
nachgelesen werden. 

Bei der Auslösung des Transfers müssen die folgenden Felder im [TransferTask.xml](TransferTask.xml) 
(markiert mit <...> Klammern) gesetzt werden:

| Default Value             | Beschreibung                                    | lokaler Value                                |
|---------------------------|-------------------------------------------------|----------------------------------------------|
| `<date-time>`             | Datum der Erstellung                            | z.B. `2025-04-14T14:16:00+01:00` |
| `<dic-identifier-value>`  | Identifikationswert DIZ (Quelle: MeasureReport) | z.B. `ukhd.de`                   |

Um den Transfer auszulösen, muss [TransferTask.xml](TransferTask.xml) an den DIZ FHIR Server gesendet werden.

Senden des Tasks an den DIZ FHIR Server mit curl

```
curl \
--cert client-certificate.pem \
--key client-certificate_private-key.pem \
-H "Accept: application/fhir+xml" -H "Content-Type: application/fhir+xml" \
-d @task.xml \
https://<fhir-base-url>/fhir/Task
```

- `TransferTask.xml` korrespondierende Task resource
- `client-certificate.pem` client certificate der BPE?
- `client-certificate_private-key.pem` zum client certificate gehörender private key
- `<fhir-base-url>` Base URL vom DIZ FHIR Server

### 4. Auslösen des dataSendStart Tasks im DSF Frontend

Der Datensendeprozess kann im DSF Frontend gestartet werden, indem die folgende URL 
aufgerufen wird (<dsf-fhir-base-url> muss durch die Basis-URL des DSF FHIR Servers ersetzt werden): 

```
https://<dsf-fhir-base-url>/fhir/Task?status=draft&identifier=http://dsf.dev/sid/task-identifier|http://medizininformatik-initiative.de/bpe/Process/dataSend/1.0/dataSendStart
```

Mit den folgenden Eintragungen im Input Bereich wird der Datentransfer mit "Start Process" gestartet. 

dms-identifier
- `http://dsf.dev/sid/organization-identifier`
- `forschen-fuer-gesundheit.de`

project-identifier
- `http://medizininformatik-initiative.de/sid/project-identifier`
- `num-con-mon`


---

## Voraussetzungen

1. **`jq` installieren**:

Für die Erstellung der CSV Dateien (https://jqlang.org/).

```bash
sudo apt-get install jq
 ```

2. **`blazectl` herunterladen und installieren**:

Zur Auswertung der Measure (Download und Anleitung unter https://github.com/samply/blazectl).
Measures können auch manuell über die FHIR-API und die FHIR-Operation $evaluate-measure ausgeführt werden.
blazectl verwendet nur diese FHIR-API.

3. **Babashka** (nur für die Generierung der Testdaten)

```sh
brew install borkdude/brew/babashka
```

1. **Docker** (nur für den Betrieb der Testumgebung inklusive Blaze)
