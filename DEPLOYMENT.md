# Instructions for Deployment

## Prerequisites

- [blazectl](https://github.com/samply/blazectl)
- [jq](https://jqlang.org/)
- [curl](https://curl.se/)
- [DSF](https://dsf.dev/) (DSF FHIR server and BPE)

## 1. Evaluate NUM_CON_MON on FHIR Server

Evaluate a [Measure](num-con-mon.yml) against the resources of the given FHIR server. The resulting MeasureReport is saved as `report-de-identified.json`.

```sh
./evaluate-measure.sh <your-fhir-server>
```

## 2. Send MeasureReport to DSF

Send the MeasureReport along with a corresponding DocumentReference to `your-dsf-fhir-server`, which should be accessible
by your DSF BPE. The DSF FHIR server can but does not have to be the FHIR server from [step 1](#1-evaluate-num_con_mon-on-fhir-server). This depends on how 
your DSF is set up.

If there already is a DocumentReference with the same project identifier system and value at the DSF FHIR server, the
DocumentReference will be updated to point to the new MeasureReport. Any previous MeasureReport will not be updated or 
deleted and will be kept on your FHIR Server.

```sh
./send-report.sh report-de-identified.json <your-dsf-fhir-server>
```

```
Usage: send-report.sh <report-file> <report-server>
       send-report.sh <report-file> <report-server> [-u <user> -p <password>]
       send-report.sh <report-file> <report-server> [-i <issuer-url> -c <client-id> -s <client-secret>]
```

## 3. Trigger Transfer from DIC to HRP

Send the MeasureReport from the DIC FHIR server to the HRP FHIR server. This is done with the 
[MII Data Transfer Process](https://github.com/medizininformatik-initiative/mii-process-data-transfer). For a better 
understanding, a detailed description on how this process works can be found 
[here](https://github.com/medizininformatik-initiative/mii-process-data-transfer/wiki). When triggering the transfer,
the following fields must be set in the [task resource](TransferTask.xml) (marked with <...> brackets) which triggers the dataSend:
* `dic-identifier-system` - the identifier system of your DIC
* `dic-identifier-value` - the identifier value of your DIC
* `hrp-identifier-system` - the identifier system of the HPR (where the MeasureReport will be transferred to)
* `hrp-identifier-value` - the identifier value of the HRP (where the MeasureReport will be transferred to)

To trigger the transfer, the [task](TransferTask.xml) must simply be sent to the DIC DSF FHIR server.

Example of sending the task to the DIC DSF FHIR server using curl, based on a 
[test setup](https://github.com/medizininformatik-initiative/mii-processes-test-setup/blob/main/docker/README-Process-Data-Transfer.md):

```
curl -H "Accept: application/xml+fhir" -H "Content-Type: application/fhir+xml" \
-d @TransferTask.xml \
--ssl-no-revoke --cacert cert/ca/testca_certificate.pem \
--cert cert/Webbrowser_Test_User/Webbrowser_Test_User_certificate.pem \
--key cert/Webbrowser_Test_User/Webbrowser_Test_User_private-key.pem \
--pass password \
https://dic1/fhir/Task
```
