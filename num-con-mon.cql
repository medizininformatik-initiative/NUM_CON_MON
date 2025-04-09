library "num-con-mon"
using FHIR version '4.0.0'
include FHIRHelpers version '4.0.0'

codesystem consent: 'urn:oid:2.16.840.1.113883.3.1937.777.24.5.3'
codesystem IdentifierType: 'http://fhir.de/CodeSystem/identifier-type-de-basis'
codesystem Kontaktebene: 'http://fhir.de/CodeSystem/Kontaktebene'

code "MDAT wissenschaftlich nutzen EU DSGVO NIVEAU": '2.16.840.1.113883.3.1937.777.24.5.3.8' from consent
code "KKDAT 5J retrospektiv wissenschaftlich nutzen": '2.16.840.1.113883.3.1937.777.24.5.3.13' from consent
code KVZ10: 'KVZ10' from IdentifierType
code GKV: 'GKV' from IdentifierType

context Patient

define "Cohort 1":
  exists (from [Consent] C
    where C.provision.provision.code.coding contains "MDAT wissenschaftlich nutzen EU DSGVO NIVEAU")

define Consent:
  from [Consent] C
    where C.provision.provision.code.coding contains "KKDAT 5J retrospektiv wissenschaftlich nutzen"

define "Cohort 2":
  exists (Consent)

define IkNumber:
  Patient.identifier.where(type ~ KVZ10 or type ~ GKV).assigner.identifier.value.first()

define Encounters:
  from [Encounter: Code 'abteilungskontakt' from Kontaktebene] E
    with Consent C
      such that Abs(months between E.period.start and C.dateTime) <= 2
    where E.status = 'finished' or E.status = 'in-progress'
    sort by period.start

define DepartmentKey:
   First(First(Encounters).serviceType.coding.where(system = 'http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel').code)

define Gender:
  if Patient.gender = 'other' then
    case
      when Patient.gender.extension.where(url = 'http://fhir.de/StructureDefinition/gender-amtlich-de').value.code = 'D' then 'divers'
      when Patient.gender.extension.where(url = 'http://fhir.de/StructureDefinition/gender-amtlich-de').value.code = 'X' then 'unbestimmt'
      else 'other'
    end
  else
    Patient.gender

define AgeClass:
  case
    when AgeInYears() < 18 then '<18J.'
    when AgeInYears() < 65 then '18-64J.'
    when AgeInYears() is not null then '65+J.'
    else 'unknown'
  end
