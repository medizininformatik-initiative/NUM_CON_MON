library "num-con-mon"
using FHIR version '4.0.0'
include FHIRHelpers version '4.0.0'

codesystem consent: 'urn:oid:2.16.840.1.113883.3.1937.777.24.5.3'
codesystem IdentifierType: 'http://fhir.de/CodeSystem/identifier-type-de-basis'

code "MDAT wissenschaftlich nutzen EU DSGVO NIVEAU": '2.16.840.1.113883.3.1937.777.24.5.3.8' from consent
code "KKDAT 5J retrospektiv wissenschaftlich nutzen": '2.16.840.1.113883.3.1937.777.24.5.3.13' from consent

context Patient

define "Cohort 1":
  exists (from [Consent] C
    where C.provision.provision.code.coding contains "MDAT wissenschaftlich nutzen EU DSGVO NIVEAU")

define "Cohort 2":
  exists (from [Consent] C
    where C.provision.provision.code.coding contains "KKDAT 5J retrospektiv wissenschaftlich nutzen")

define IkNumber:
  Patient.identifier.where(type ~ Code 'GKV' from IdentifierType).assigner.identifier.value.first()

define DepartmentKey:
   First(from [Encounter] E
     return E.serviceType.coding.where(system = 'http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel').code.first())

define Gender:
  Patient.gender

define AgeClass:
  case
  when AgeInYears() < 18 then '<18J.'
  when AgeInYears() < 65 then '18-64J.'
  when AgeInYears() is not null then '65+J.'
  else 'unknown'
  end
