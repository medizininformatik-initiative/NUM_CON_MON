# NUM-CON-MON

CQL Measure for the NUM-CON-MON project.

---

## Content

1. [Description](#description)
1. [Files](#files)
1. [Deployment](#deployment)
    1. [Evaluate Measure](#i-evaluate-measure)
    1. [Upload MeasureReport](#ii-upload-measurereport)
    1. [DSF DataTransfer](#iii-dsf-datatransfer)
1. [Prerequisites](#prerequisites)
1. [Setting up the Test Environment](#setting-up-the-test-environment)

---

## Description

1. Evaluates a Measure resource on a FHIR server.
1. Extracts the following data:
    -   Total number of patients in two cohorts.
    -   Breakdown for Cohort 2:
        -   Distribution of health insurance affiliation by location.
        -   Distribution by department.
        -   Distribution by gender.
        -   Distribution by age group (<18 years, 18–64 years, 65+ years).
1. Stores the extracted data in CSV files for easy analysis and as a FHIR MeasureReport in a JSON file.

---

## Files

-   `num-con-mon.yml`: Measure definition in YAML format
-   `num-con-mon-cql`: CQL-script containing the definitions for resource counts
-   `ik-number.jq`: jq-script for determining the distribution of health insurance affiliation
-   `department-key.jq`: jq-script for determining the distribution by department
-   `gender.jq`: jq-script for determining the distribution by gender
-   `age-class.jq`: jq-script for determining the distribution by age group
-   `de-identify.jq`: jq-script for anonymizing data by aggregating small populations
-   `util.jq`: jq-script defining helper functions for processing "data-absent-reason" & for counting data.

---

## Deployment 

For deployment purposes, it is essential to distinguish between the **DIC FHIR server** and the **DSF FHIR server**.
The **DIC FHIR server** houses all CDS-related FHIR resources. In contrast, the **DSF FHIR server**, alongside BPE,
constitutes a primary component of the DSF, containing the necessary FHIR resources for the DSF process workflow.

### i. Evaluate Measure

Execute the `evaluate-measure.sh` script, passing the URL of the **DIC FHIR server** as a parameter. If no URL is provided, 
`http://localhost:8080/fhir` is used by default:

```bash
./evaluate-measure.sh <dic-fhir-base-url>
```

`evaluate-measure.sh` automates the evaluation of a Measure YAML file on the **DIC FHIR server**. A detailed report is created, 
and specific metrics are extracted into CSV files for further analysis. The script generates the following files:

- `report-de-identified.json`: The MeasureReport in JSON format.
- `ik-number.csv`: Distribution of health insurance fund affiliation by location.
- `department-key.csv`: Distribution by department.
- `gender.csv`: Distribution by gender.
- `age-class.csv`: Distribution by age groups.

### ii. Upload MeasureReport

For data transfer via DSF, the `report-de-identified.json` MeasureReport must be sent with an associated DocumentReference 
to the **DIC FHIR server** (assuming this is also the FHIR server which is configurated in the BPE docker-compose-yml for [DE_MEDIZININFORMATIK_INITIATIVE_DATA_TRANSFER_DIC_FHIR_SERVER_BASE_URL](https://github.com/medizininformatik-initiative/mii-process-data-transfer/wiki/Process-Data-Transfer-Configuration-v1.0.x.x#de_medizininformatik_initiative_data_transfer_dic_fhir_server_base_url)). This is accomplished using the `send-report.sh` script. If a DocumentReference with the same project identification system (`http://medizininformatik-initiative.de/fhir/CodeSystem/data-transfer`) 
and value (`num-con-mon`) already exists on the **DIC FHIR server**, the DocumentReference is updated to point to the new MeasureReport. A previous MeasureReport is not updated or deleted and remains on the **DIC FHIR server**.

```bash
./send-report.sh report-de-identified.json <dic-fhir-base-url>
```

```
send-report.sh <report-file> <report-server>
send-report.sh <report-file> <report-server> [-u <user> -p <password>]
send-report.sh <report-file> <report-server> [-i <issuer-url> -c <client-id> -s <client-secret>]
```

### iii. DSF DataTransfer

Using the [MII DataTransfer process](https://github.com/medizininformatik-initiative/mii-process-data-transfer),
the MeasureReport can be sent from the **DIC FHIR server** to the **HRP FHIR server**. A detailed description
of the DataTransfer process can be found [here](https://github.com/medizininformatik-initiative/mii-process-data-transfer/wiki).

There are two possibilities to execute the DataTransfer process.

**(a) Via Command Line**

For triggering the transfer, the [TransferTask.xml](TransferTask.xml) file must be sent to the **DSF FHIR server** with 
the corresponding entries. The following fields are relevant (marked with `<...>` brackets):

| Default Value                | Description                                       | Local Value                       |
|------------------------------|---------------------------------------------------|-----------------------------------|
| `<date-time>`                | Date of creation                                  | e.g., `2025-04-14T14:16:00+01:00` |
| `<dic-identifier-value>`     | DIC identification value (Source: MeasureReport)  | e.g., `ukhd.de`                   |


**Sending the task to the DSF FHIR server with curl**

```
curl \
--cert client-certificate.pem \
--key client-certificate_private-key.pem \
-H "Accept: application/fhir+xml" -H "Content-Type: application/fhir+xml" \
-d @TransferTask.xml \
https://<dsf-fhir-base-url>/Task
```

- `TransferTask.xml` corresponding task resource
- `<dsf-fhir-base-url>` base URL of the **DSF FHIR server**
- `client-certificate.pem` client certificate
- `client-certificate_private-key.pem` private key belonging to the client certificate

**(b) Via DataSendStart Task in the DSF Frontend**

The DataTransfer process can be started in the DSF frontend by calling the following URL (replace `<dsf-fhir-base-url>` 
with the base URL of the **DSF FHIR server**):

```
https://<dsf-fhir-base-url>/Task?status=draft&identifier=http://dsf.dev/sid/task-identifier|http://medizininformatik-initiative.de/bpe/Process/dataSend/1.0/dataSendStart
```

The Task is triggered by clicking the 'Start Process' button and entering the following values in the input fields:

dms-identifier
- `http://dsf.dev/sid/organization-identifier`
- `forschen-fuer-gesundheit.de`

project-identifier
- `http://medizininformatik-initiative.de/sid/project-identifier`
- `num-con-mon`

---

## Prerequisites

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

### Setting up the Test Environment

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
