# NUM-CON-MON

CQL Measure for the NUM-CON-MON project.

## **Content**

1. [Description](#description)
2. [Files](#files)
3. [Deployment](#deployment)
    - [1. Evaluate Measure](#1-evaluate-measure)
    - [2. Upload MeasureReport](#2-upload-measurereport)
    - [3. DataTransfer Preparation (One-Time)](#3-preparation-datatransfer-one-time)
    - [4. Trigger `dataSendStart` Task in DSF Frontend](#4-trigger-datasendstart-task-in-the-dsf-frontend)
4. [Prerequisites](#prerequisites)
6. [Setting up the Test Environment & Test Data Transfer](#setting-up-the-test-environment--test-data-transfer)

---

## **Description**

1.  Evaluates a Measure resource on a FHIR server.
2.  Extracts the following data:
    -   Total number of patients in two cohorts.
    -   Breakdown for Cohort 2:
        -   Distribution of health insurance affiliation by location.
        -   Distribution by department.
        -   Distribution by gender.
        -   Distribution by age group (<18 years, 18–64 years, 65+ years).
3.  Stores the extracted data in CSV files for easy analysis and as a FHIR MeasureReport in a JSON file.

---

## **Files**

-   `num-con-mon.yml`: Measure definition in YAML format
-   `num-con-mon-cql`: CQL-script containing the definitions for resource counts
-   `ik-number.jq`: jq-script for determining the distribution of health insurance affiliation
-   `department-key.jq`: jq-script for determining the distribution by department
-   `gender.jq`: jq-script for determining the distribution by gender
-   `age-class.jq`: jq-script for determining the distribution by age group
-   `de-identify.jq`: jq-script for anonymizing data by aggregating small populations
-   `util.jq`: jq-script defining helper functions for processing "data-absent-reason" & for counting data.

---

## **Deployment**  

### **1. Evaluate Measure**

Execute the `evaluate-measure.sh` script, passing the URL of the FHIR server as a parameter. If no URL is provided, 
`http://localhost:8080/fhir` is used by default:

```bash
./evaluate-measure.sh <dic-fhir-base-url>/fhir
```

`evaluate-measure.sh` automates the evaluation of a Measure YAML file on a FHIR server. A detailed report is created, 
and specific metrics are extracted into CSV files for further analysis. The script generates the following files:

- `report-de-identified.json`: The MeasureReport in JSON format.
- `ik-number.csv`: Distribution of health insurance fund affiliation by location.
- `department-key.csv`: Distribution by department.
- `gender.csv`: Distribution by gender.
- `age-class.csv`: Distribution by age groups.


## **Deployment**

### **1. Evaluate Measure**

Executes the `evaluate-measure.sh` script, passing the URL of the FHIR server as a parameter. If no URL is specified, 
the default `http://localhost:8080/fhir` is used:

```bash
./evaluate-measure.sh <dic-fhir-base-url>/fhir
```

`evaluate-measure.sh` automates the evaluation of a Measure-YAML file on a FHIR server. It generates a detailed report 
and extracts specific metrics into CSV files for further analysis. The script produces the following files:

-   `report-de-identified.json`: The MeasureReport in JSON format.
-   `ik-number.csv`: Distribution of health insurance affiliation by location.
-   `department-key.csv`: Distribution by department.
-   `gender.csv`: Distribution by gender.
-   `age-class.csv`: Distribution by age group.

---

### **2. Upload MeasureReport**

For data transfer via DSF, the `report-de-identified.json` MeasureReport must be sent with an associated DocumentReference 
to the FHIR server connected to DSF (BPE). This is accomplished using the `send-report.sh` script. If a DocumentReference 
with the same project identification system (`http://medizininformatik-initiative.de/fhir/CodeSystem/data-transfer`) 
and value (`num-con-mon`) already exists on the FHIR server, the DocumentReference is updated to point to the new MeasureReport. 
A previous MeasureReport is not updated or deleted and remains on the FHIR server.

```bash
./send-report.sh report-de-identified.json <dic-fhir-base-url>/fhir
```

```
send-report.sh <report-file> <report-server>
send-report.sh <report-file> <report-server> [-u <user> -p <password>]
send-report.sh <report-file> <report-server> [-i <issuer-url> -c <client-id> -s <client-secret>]
```
---

### **3. Preparation DataTransfer (one-time)**

Using the [MII Data Transfer Process](https://github.com/medizininformatik-initiative/mii-process-data-transfer), 
the MeasureReport can be sent from the dic FHIR server connected to DSF to the HRP FHIR server. A detailed description 
of the DataTransfer process can be found [here](https://github.com/medicininformatik-initiative/mii-process-data-transfer/wiki).
Before triggering the transfer, the [TransferTask.xml](TransferTask.xml) file must be sent to the dic FHIR server with 
the corresponding entries. The following fields are relevant (marked with `<...>` brackets):

| Default Value                | Description                                       | Local Value                       |
|------------------------------|---------------------------------------------------|-----------------------------------|
| `<date-time>`                | Date of creation                                  | e.g., `2025-04-14T14:16:00+01:00` |
| `<dic-identifier-value>`     | DIC identification value (Source: MeasureReport)  | e.g., `ukhd.de`                   |


**Sending the Task to the DIC FHIR Server with curl**

```
curl \
--cert client-certificate.pem \
--key client-certificate_private-key.pem \
-H "Accept: application/fhir+xml" -H "Content-Type: application/fhir+xml" \
-d @TransferTask.xml \
https://<dic-fhir-base-url>/fhir/Task
```

- `TransferTask.xml` corresponding Task resource
- `<dic-fhir-base-url>` Base URL of the DIC FHIR Server

optional (if the DIC FHIR Server requires authentication):

- `client-certificate.pem` Client certificate
- `client-certificate_private-key.pem` Private key belonging to the Client certificate

---

### **4. Trigger dataSendStart Task in the DSF Frontend**

The data transfer process can be started in the DSF frontend by calling the following URL (replace `<dsf-fhir-base-url>` 
with the base URL of the DSF FHIR server):

```
https://<dsf-fhir-base-url>/fhir/Task?status=draft&identifier=http://dsf.dev/sid/task-identifier|http://medizininformatik-initiative.de/bpe/Process/dataSend/1.0/dataSendStart
```

The data transfer is started with "Start Process" using the following entries in the input area:

dms-identifier
- `http://dsf.dev/sid/organization-identifier`
- `forschen-fuer-gesundheit.de`

project-identifier
- `http://medizininformatik-initiative.de/sid/project-identifier`
- `num-con-mon`

---

## **Prerequisites**

1. **Install `jq`**:
   For creating the CSV files (https://jqlang.org/).
```bash
sudo apt-get install jq
 ```

2. **Download and install `blazectl`**:
   For evaluating the Measure (Download and instructions at https://github.com/samply/blazectl).
   Measures can also be executed manually via the FHIR API and the $evaluate-measure FHIR operation.
   blazectl only uses this FHIR API.

3. **Babashka** (only for generating test data)
```sh
brew install borkdude/brew/babashka
```

4. **Docker** (only for running the test environment including Blaze)

---

## **Setting up the Test Environment & Test Data Transfer**

1. Start Blaze
```sh
docker compose up -d
```

2. Generate test data
```sh
./gen-test-data.clj
```

3. Import test data
```sh
./import-data.sh
```

4. Evaluate Measure
```sh
./evaluate-measure.sh
```

5. Upload MeasureReport
```sh
./send-report.sh report-de-identified.json http://localhost:8080/fhir
```

Send the Task to the dic FHIR Server using curl
based on a [Test Setup](https://github.com/medizininformatik-initiative/mii-processes-test-setup/blob/main/docker/README-Process-Data-Transfer.md):
```
curl -H "Accept: application/xml+fhir" -H "Content-Type: application/fhir+xml" \
-d @TransferTask.xml \
--ssl-no-revoke --cacert cert/ca/testca_certificate.pem \
--cert cert/Webbrowser_Test_User/Webbrowser_Test_User_certificate.pem \
--key cert/Webbrowser_Test_User/Webbrowser_Test_User_private-key.pem \
--pass password \
https://dic1/fhir/Task
```

6. Stop Blaze and remove data (delete docker volume)
```sh
docker compose down -v
```
